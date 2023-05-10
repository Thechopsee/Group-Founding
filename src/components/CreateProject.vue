<template>
    <div class="modal-content">
      <form @submit.prevent="submitForm">
        <label for="name">Name:</label>
        <input type="text" id="name" v-model="name" required>
  
        <label for="description">Description:</label>
        <textarea id="description" v-model="description" required></textarea>
  
        <label for="targetAmount">Target Amount:</label>
        <input type="number" step="0.00000000000000001" id="targetAmount" v-model.number="targetAmount" required>
  
        <label for="deadline">Deadline:</label>
        <input type="datetime-local" id="deadline" v-model="deadline" required><br>
        <br>
        <button type="submit" class="button">Create Project</button>
      </form>
    </div>
  </template>
  
  
  <script lang="ts">
  import { defineComponent } from 'vue';
  import {BigNumber, Contract, ethers, providers} from 'ethers'
  import {ProjectRegistry} from '../../typechain-types/ProjectRegistry'
  import registryAdress from '../../projectRegistry.json'
  import registryABI from '../../artifacts/contracts/ProjectRegistry.sol/ProjectRegistry.json'
import { boolean } from 'hardhat/internal/core/params/argumentTypes';
  
  export default defineComponent({
    props: {
      refresh: {
      type: Function,
      required: true,
    },
    chngModal: {
      type: Function,
      required: true
    },

    },
    data() {
      return {
        name: '',
        description: '',
        targetAmount: 0.1,
        deadline: '',
      };
    },
    methods: {
        async submitForm() {
            
            let user: ethers.providers.JsonRpcSigner | null = null;
            let provider: ethers.providers.Web3Provider | null = null;
            provider = new ethers.providers.Web3Provider((window as any).ethereum);
            user = provider.getSigner();
            const unixTime = Date.parse(this.deadline) / 1000; // převod na Unix timestamp
            const unixTimestart =BigInt(Date.now()) / 1000n;
            if(unixTime<unixTimestart)
            {
              alert("Deadline must be more then one minute after create time");
            }
            const projectRegistry = new Contract(
                registryAdress.address,
                registryABI.abi,
                user
            ) as ProjectRegistry;
            if(this.targetAmount<0)
            {
                alert("TargetAmount must be >0");
            }
            const weiValue = ethers.utils.parseUnits(this.targetAmount+"", "ether");
            
            try{
            const tx = await projectRegistry.createProject(
                                        this.name,
                                        this.description,
                                        weiValue,
                                        unixTime,
                                        unixTimestart
                                      );
            tx.wait()
            const receipt = await tx.wait();
            this.refresh();
            }
            catch(error)
            {
              alert("Something went wrong:"+error);
              return;
            }
            this.name="";
            this.description="";
            this.targetAmount=0.0;
            this.deadline="";
            this.chngModal();
           


            

    },

  }});
  </script>

<style>
  .modal-content {
    background-color: #f8f8f8;
    border: 1px solid #ccc;
    border-radius: 5px;
    padding: 20px;
    width: 100%;
    max-width: 500px;
    margin: 0 auto;
  }
  
  label {
    display: block;
    color:#32a672;
    font-size: 18px;
    margin-bottom: 10px;
  }
  
  input[type="text"], 
  textarea,
  input[type="number"] {
    border: 1px solid #ccc;
    border-radius: 3px;
    font-size: 16px;
    padding: 10px;
    width: 100%;
    margin-bottom: 20px;
  }
  
  input[type="text"]:focus,
  textarea:focus,
  input[type="number"]:focus {
    border: 1px solid #3498db;
  }
  


  input[type="datetime-local"] {
  background-color: #f2f2f2;
  color: #333;
  padding: 8px;
  border: none;
  border-radius: 4px;
  box-shadow: 0 0 4px rgba(0, 0, 0, 0.2);
}

</style>