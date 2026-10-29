# MoMo Wallet

A fully-featured mobile wallet application built with Flutter, Firebase Authentication, and Cloud Firestore for the Mobile Programming course (Innovation Center / Week 2 & 3 Mini Project).

---

## 📱 Project Overview
**MoMo Wallet** simulates mobile money services commonly used in Rwanda. It handles incoming deposits, sending money to friends, cashing out at an agent with an exact note breakdown, live statistics, and strict ledger safety rules backed by Firebase cloud storage.

---

## ✨ Features & Requirements Implemented
1. **Cloud Authentication & Backend (Session 6):**
   - Secure Email/Password authentication (`FirebaseAuth`) with account creation, login, and logout.
   - Real-time cloud sync with **Cloud Firestore**, storing each user's transactions privately under `users/{userId}/transactions`.
2. **Wallet Dashboard (Session 4):**
   - Starts with sample transactions and an initial balance of **10,000 RWF**.
   - Displays current balance in a prominent card, formatted with comma separators.
3. **Transaction Management & Filtering:**
   - Lists transactions (newest first) indicating IN (green) or OUT (red).
   - Filter chips to view **All**, **IN**, or **OUT** transactions instantly.
   - Deletion support with a **SnackBar Undo** action.
   - **Historical Balance Safety Guard:** Refuses any transaction deletion if it would cause the historical balance to drop below 0 RWF at any past point.
4. **Send Money:**
   - Validates Rwandan phone numbers (exactly 10 digits starting with `078` or `079`).
   - Validates amount (at least 100 RWF and not exceeding current balance).
5. **Cash Out Calculator:**
   - Validates amounts as multiples of 100 RWF.
   - Previews the exact cash notes the agent will hand over (5,000, 2,000, 1,000, 500, and 100 RWF notes, biggest first) before confirmation.
6. **Statistics Card:**
   - Tracks **Total IN**, **Total OUT**, and **Lowest Balance** ever reached.

---

## 🤔 Think Questions & Answers

### 1. Why must every check happen before any money moves? What would go wrong if one check came after?
* **Answer:** Checking all validation rules (such as sufficient balance, valid phone prefix, and positive amounts) before executing a transaction ensures absolute ledger integrity. If a check came after money moved, the app could enter an inconsistent state where funds are deducted or sent before catching an error, resulting in corrupted balances, race conditions, or unauthorized negative balances.

### 2. Your lowest-balance statistic needs a starting value. What did you start it at, and why not 0?
* **Answer:** We initialize it based on the initial balance (e.g. 10,000 RWF). Starting at 0 would be incorrect because the wallet already starts with 10,000 RWF before any expenses occur, so initializing at 0 would falsely report 0 as the lowest balance immediately upon app launch.

---

## 🛠️ Tech Stack
* **Framework:** Flutter (Dart)
* **Backend & Database:** Firebase Authentication & Cloud Firestore
* **State Management:** StatefulWidget, StreamBuilder
* **Testing:** Flutter Test (Unit & Widget tests)
