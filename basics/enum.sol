// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract enumTest {
    enum status { Not_Started , Initiated, Pending, Process, Complete }

    status public txStatus;

    function createTx() public {
        txStatus = status.Initiated;
    }

    function pendingTx() public  {
        txStatus = status.Pending;
    }

    function processTx() public {
        txStatus = status.Process;
    }

    function completeTx() public  {
        txStatus = status.Complete;
    }

    function getStatus() public view returns (string memory){
        if(txStatus == status.Initiated) {
            return "Initiated";
         } else { 
            if (txStatus == status.Pending) {
                return  "Pending";
            } else {
                if (txStatus == status.Process) {
                    return "Process";
                } else {
                    if (txStatus == status.Complete) {
                        return "Completed";
                    } else {
                        return "Not Started";
                    }
                }
            }
        }   
    }
}