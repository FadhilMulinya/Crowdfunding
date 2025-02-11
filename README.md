
---

# **Crowdfunding  - Soulbound Token (SBT) Integration**  

## **Overview**  
This is a **decentralized crowdfunding platform** , where charities can receive crypto donations, and donors are rewarded with **Soulbound Tokens (SBTs)**. These **non-transferable NFTs** represent donor reputation and achievements.  

## **Features**  
✅ **Decentralized Crowdfunding** – Crypto donations to verified charities.  
✅ **Soulbound Tokens (SBTs)** – Non-transferable NFTs tracking donor contributions.  
✅ **Automated Donor Recognition** – SBTs dynamically update with each donation.  
✅ **IPFS Metadata Storage** – Secure and decentralized donor data.  
✅ **Built with Foundry** – Fast, efficient smart contract development.  

---

## **Getting Started**  

### **1️⃣ Clone the Repository**  
```sh
git clone git@github.com:FadhilMulinya/Crowdfunding.git
cd Crowdfunding
```

### **2️⃣ Install Dependencies**  
Ensure you have **Foundry** installed:  
```sh
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### **3️⃣ Install OpenZeppelin Contracts**  
Run the script to install **OpenZeppelin** dependencies:  
```sh
forge install OpenZeppelin/openzeppelin-contracts
```

### **4️⃣ Set Up Remappings**  
Ensure your `remappings.txt` file includes:  
```
@openzeppelin/=lib/openzeppelin-contracts/
```

Alternatively, generate it automatically:  
```sh
forge remappings > remappings.txt
```

### **5️⃣ Compile the Contracts**  
```sh
forge build
```

### **6️⃣ Run Tests**  
```sh
forge test
```

### **7️⃣ Deploy the Contracts**  
To deploy on a testnet:  
```sh
forge script script/Deploy.s.sol --rpc-url <NETWORK_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast
```
Replace `<NETWORK_RPC_URL>` and `<YOUR_PRIVATE_KEY>` with the appropriate values.

---

## **How It Works**  

### **Soulbound Tokens (SBTs)**
- Donors receive an **SBT** upon their first donation.  
- The **SBT cannot be transferred**, ensuring it remains linked to the donor’s reputation.  
- **Metadata includes:**  
  - **Total donations**  
  - **Donation count**  
  - **Donor level** (**Bronze → Silver → Gold → Platinum → Diamond**)  
  - **Last donation timestamp**  

### **Donation Processing**
- When a donor contributes, their SBT is **minted or updated automatically**.  
- SBT **levels increase** as donations accumulate.  

---

## **Smart Contracts**  

| Contract        | Purpose |
|----------------|---------|
| `SBTContract.sol` | Manages **Soulbound Tokens** for donors. |
| `Crowdfunding.sol` | Handles **donations, charities, and SBT updates**. |

---

## **Interacting with the Contracts**  

### **Using Foundry Console**
1. **Mint an SBT**  
   ```sh
   cast send <SBT_CONTRACT> "mintSBT(address,string)" <DONOR_ADDRESS> "<IPFS_HASH>" --rpc-url <NETWORK_RPC_URL> --private-key <YOUR_PRIVATE_KEY>
   ```
2. **Update SBT after a donation**  
   ```sh
   cast send <SBT_CONTRACT> "updateSBT(uint256,uint256)" <TOKEN_ID> <DONATION_AMOUNT> --rpc-url <NETWORK_RPC_URL> --private-key <YOUR_PRIVATE_KEY>
   ```
3. **Get Donor Metadata**  
   ```sh
   cast call <SBT_CONTRACT> "getDonorMetadata(address)" <DONOR_ADDRESS> --rpc-url <NETWORK_RPC_URL>
   ```

---

## **Contributing**  
🙌 Contributions are welcome! Fork the repo, create a branch, and submit a PR.  

## **License**  
📝 **MIT License** - Open for all!  

---
