// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * ETHSenderPlayground
 *
 * - deposit(): setor ETH ke kontrak ini.
 * - payWithTransfer(): kirim ETH pakai `transfer` (gas ke penerima dibatasi stipend 2300).
 * - payWithSend(): kirim ETH pakai `send` (juga hanya stipend 2300, tapi return bool).
 * - payWithCall(): kirim ETH pakai `call` (meneruskan semua gas secara default; bisa disetel).
 * - credit()/withdraw(): contoh pola "pull payment" + nonReentrant untuk keamanan.
 *
 * Kenapa 2300 stipend bermasalah?
 * - `transfer`/`send` secara desain hanya memberi penerima 2300 gas (gas stipend bawaan value-call).
 * - Sejak Istanbul (EIP-1884) & Berlin (EIP-2929), beberapa opcode jadi LEBIH MAHAL
 *   (misalnya SLOAD bisa memakan ~2100 saat akses "cold"), sehingga fallback/receive
 *   yang melakukan sedikit logika (SLOAD, LOG/event, routing) bisa >2300 gas → `transfer`/`send` gampang gagal/revert.
 * - `call` tidak mengunci stipend 2300; ia meneruskan semua gas (atau jumlah yang kamu tentukan),
 *   sehingga lebih robust terhadap perubahan biaya opcode & kompatibel dgn smart wallet/proxy modern.
 *
 * Catatan keamanan:
 * - Karena `call` meneruskan gas, gunakan pola checks-effects-interactions, nonReentrant,
 *   atau (lebih aman) "pull payments" (user narik dana sendiri) untuk menghindari reentrancy.
 */
contract ETHSenderPlayground {
    event SentByTransfer(address indexed to, uint256 amount);
    event SentBySend(address indexed to, uint256 amount, bool success);
    event SentByCall(address indexed to, uint256 amount, bool success, bytes returndata);

    // Terima setoran agar kontrak punya saldo untuk demo.
    function deposit() external payable {}

    // 1) Kirim ETH dgn `transfer`
    function payWithTransfer(address payable to, uint256 amount) external {
        require(address(this).balance >= amount, "insufficient balance");

        /**
         * `transfer` mengatur gas=0 pada low-level CALL,
         * sehingga penerima hanya mendapatkan GAS STIPEND 2300.
         * Jika penerima melakukan operasi yang butuh >2300 gas (mis. SLOAD cold + event),
         * ini akan REVERT otomatis.
         */
        to.transfer(amount);

        emit SentByTransfer(to, amount);
    }

    // 2) Kirim ETH dgn `send`
    function payWithSend(address payable to, uint256 amount) external {
        require(address(this).balance >= amount, "insufficient balance");

        /**
         * `send` juga hanya memberi stipend 2300.
         * Bedanya: `send` tidak auto-revert; ia mengembalikan bool.
         * Tetap RISKAN karena mudah gagal pada penerima "boros gas".
         */
        bool ok = to.send(amount);
        require(ok, "send failed (likely >2300 gas in receiver)");
        emit SentBySend(to, amount, ok);
    }

    // 3) Kirim ETH dgn `call` (REKOMENDASI)
    function payWithCall(address payable to, uint256 amount) external {
        require(address(this).balance >= amount, "insufficient balance");

        /**
         * `call` meneruskan SEMUA gas secara default (atau bisa ditentukan manual).
         * Ini membuat pengiriman ETH lebih tahan terhadap perubahan biaya opcode (EIP-1884/2929)
         * dan kompatibel dengan kontrak penerima modern (proxy/wallet) yang butuh gas lebih.
         */
        (bool ok, bytes memory data) = to.call{value: amount}("");
        require(ok, "call failed");
        emit SentByCall(to, amount, ok, data);
    }

    /* ---------------------------------------------------------
       Pola PULL PAYMENT + nonReentrant (lebih aman dari push)
       --------------------------------------------------------- */

    mapping(address => uint256) public withdrawable;
    uint256 private locked;

    modifier nonReentrant() {
        require(locked == 0, "reentrancy");
        locked = 1;
        _;
        locked = 0;
    }

    // Kreditkan saldo tarik ke penerima (simulasi pembayaran tertunda)
    function credit(address to) external payable {
        withdrawable[to] += msg.value;
    }

    // Penerima MENARIK sendiri dananya (mengurangi risiko reentrancy pada jalur eksekusi utama)
    function withdraw() external nonReentrant {
        uint256 amount = withdrawable[msg.sender];
        require(amount > 0, "nothing to withdraw");
        withdrawable[msg.sender] = 0;

        // Tetap gunakan `call` saat mengirim ke alamat eksternal
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "withdraw failed");
    }

    // Supaya kontrak bisa terima ETH langsung
    receive() external payable {}
}

/* ---------------------------------------------------------
   Dua tipe penerima untuk uji-coba:
   - ReceiverMinimal: "ramah 2300 gas" (kosong) → transfer/send biasanya sukses.
   - ReceiverExpensive: "boros gas" (SLOAD + event) → transfer/send mudah gagal.
   --------------------------------------------------------- */

// Penerima minimal, tidak melakukan apa-apa; ideal untuk stipend 2300.
contract ReceiverMinimal {
    event Ping(address from, uint256 amount);

    // Kosong: sehemat mungkin gas; `transfer`/`send` biasanya aman.
    receive() external payable {
        // (opsional) Hindari event di sini jika ingin benar-benar hemat gas.
        // emit Ping(msg.sender, msg.value);
    }
}

// Penerima “boros gas”, mensimulasikan kontrak modern (proxy/wallet) yang butuh >2300 gas.
contract ReceiverExpensive {
    uint256 public x; // SLOAD di receive/fallback bisa mahal (terutama "cold access" pasca EIP-2929)

    event Got(address from, uint256 amount, uint256 xSnapshot);

    // Kirim ETH tanpa data → masuk ke receive()
    receive() external payable {
        // Operasi berikut sering membuat biaya >2300:
        // - SLOAD pertama (cold) ~2100 gas
        // - LOG (event) + overhead memori
        // - Sedikit logika tambahan/proxying
        uint256 snapshot = x; // SLOAD
        emit Got(msg.sender, msg.value, snapshot); // LOG
            // Dengan kombinasi ini, `transfer`/`send` kemungkinan besar REVERT/FAIL
            // sedangkan `call` tetap berhasil.
    }

    // Ada data / selector tidak dikenal → fallback()
    fallback() external payable {
        uint256 snapshot = x; // SLOAD
        emit Got(msg.sender, msg.value, snapshot); // LOG
    }
}
