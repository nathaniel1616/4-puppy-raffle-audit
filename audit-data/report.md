---
title: PasswordStoreAudit Report
author: Nathaniel Yeboah
date: June 9, 2024
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
    {\Huge\bfseries PasswordStore Audit Report\par}
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

This is a password store contract where users can store their passwords. Only the owner can set the password and view the password . The contract emits an event when a password is set.

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
Commit hash: 7d55682ddc4301a7b13ae9413095feffd9924566

```

## Scope 
** The audit report is based on the following files: **

```
src/PasswordStore.sol
```

## Roles

- **Owner:** The owner of the contract can set the password of the contract and view the password of the contract.
- **Others:** No one else can set the password of the contract or view the password of the contract.
  
# Executive Summary

* Add some notes about how the audit went, what was found, types of things you found *

* We spend about 5 hours with 1 auditors using foundry *

## Issues found
 | Severity | Number of issues found |
 | -------- | ---------------------- |
 | High     | 2                      |
 | Medium   | 0                      |
 | Low      | 0                      |
 | Info     | 1                      |
 | Total    | 3                      |


# Findings


