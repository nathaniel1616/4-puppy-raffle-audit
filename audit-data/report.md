---
title: PuppyRaffle Audit Report
author: Nathaniel Yeboah
date: June 20, 2024
header-includes:
  - \usepackage{titling}
  - \usepackage{graphicx}
---

\begin{titlepage}
    \centering
    \begin{figure}[h]
        \centering
        \includegraphics[width=0.5\textwidth]{logo.pdf} 
    \end{figure}
    \vspace*{2cm}
    {\Huge\bfseries PuppyRaffle Audit Report\par}
    \vspace{1cm}
    {\Large Version 1.0\par}
    \vspace{2cm}
    {\Large\itshape Nathaniel Yeboah\par}
    \vfill
    {\large \today\par}
\end{titlepage}

\maketitle

<!-- Your report starts here! -->

Prepared by: Nathaniel Yeboah
 Auditor: 
- Nathaniel Yeboah


# Table of Contents
- [Table of Contents](#table-of-contents)
- [Protocol Summary](#protocol-summary)
- [Disclaimer](#disclaimer)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
  - [Roles](#roles)
- [Executive Summary](#executive-summary)
  - [Issues found](#issues-found)
- [Findings](#findings)

# Protocol Summary
This project allows users to enter a reaffle to win a cute dog NFT. The protocol should do the folllowing:
1. player enters the raffle by calling the payable `enterRaffle` function . total entrance fee is based on the the basic entrance fee * the number of participants.
2. Players can choose to get a refund by calling the `refund` function, which sends the entrance fee back to the player.
3. A winner is selected after X amount of time and is minted a  puppy. The random selection is based on the hash of the block difficulty annd msg.sender address
4.  The owner of the protocol will set a feeAddress to take a cut of the `value`, and the rest of the funds will be sent to the winner.
5.  The owner can set the address of the feeAddress .

# Disclaimer

The Security Researcher makes all effort to find as many vulnerabilities in the code in the given time period, but holds no responsibilities for the findings provided in this document. A security audit by the team is not an endorsement of the underlying business or product. The audit was time-boxed and the review of the code was solely on the security aspects of the Solidity implementation of the contracts.

# Risk Classification

|            |        | Impact |        |     |
| ---------- | ------ | ------ | ------ | --- |
|            |        | High   | Medium | Low |
|            | High   | H      | H/M    | M   |
| Likelihood | Medium | H/M    | M      | M/L |
|            | Low    | M      | M/L    | L   |

We use the [CodeHawks](https://docs.codehawks.com/hawks-auditors/how-to-evaluate-a-finding-severity) severity matrix to determine severity. See the documentation for more details.

# Audit Details 

** The findings described in this report are based on the code at the following commit hash: **
```
Commit hash: e30d199697bbc822b646d76533b66b7d529b8ef5

```

## Scope 
** The audit report is based on the following files: **

```
src/PuppyRaffle.sol
```

## Roles

- Players: Can enter the raffle and get a refund and stand a chance for winner the raffle 
- Owner: Can set the feeAddress and withdraw fees  and deployer the raffle contract
  
# Executive Summary

* Add some notes about how the audit went, what was found, types of things you found *

* We spend about 5 hours with 1 auditors using foundry *

## Issues found
 | Severity | Number of issues found |
 | -------- | ---------------------- |
 | High     | 5                      |
 | Medium   | 4                      |
 | Low      | 2                      |
 | Info     | 5                      |
 | Gas      | 3                      |
 | Total    | 19                     |



# Findings


