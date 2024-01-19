# SAVVY

## Pages

1. Home Page
   - SAVVY Introduction and Description
   - Connect Family Wallet using ConnectKit
2. Register Page
   - This page appears if the connected wallet is not registered in the contracts
   - Three options. Teacher, Parent, Student
   - Choosing Teacher, Goes to Create Page
   - Choosing Parent/Student, Goes to Join Page
3. Create Page
   - Enter Details of the Class
   - Enter the whitelisted address list for Parents ( csv import )
   - Enter the whitelisted address list for students ( csv import )
   - Enter the amount per day
   - Enter the duration of each window to delegate credits to the students
   - Enter the total deposit amount
   - Finally, it deploys a vault. Users supplies all the USDC, USDT or DAI and delegates the credits to the vault.
4. Join Page
   - Choose an option. Parent or Student
   - Enter code/Vault Address/Teacher Address.
   - Check if the user wallet address is valid and then adds them to the class.
5. Dashboard Page
   - If Teacher
     - View available loan amount
     - View Health factor
     - View amount of days the collateral would suffice
     - View net gains
     - View all transactions and activity History of students in the class
     - View analytical data
   - If Student
     - View Total amount staked
     - View Total available credits
     - View Countdown to next credits
     - Available credit per window
     - Total Profit/Loss
     - View Transactions and Activity History
   - If Tutor
     - Similar to Student
