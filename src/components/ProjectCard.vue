<template>
  <div class="project-card">
    <h2>{{ project.name }}</h2>
    <p id="owner">{{ project.owner }}</p>
    <p>{{ project.description }}</p>
    <p>
      Deadline: {{ deadline }}
      <br />
      Target amount: {{ project.targetAmount }} ETH  
    </p>
    <progress :value="project.actualAmount" :max="project.targetAmount"></progress> Funded: {{ project.actualAmount }} ETH / {{ project.actualAmount*100/project.targetAmount }} %
    <div v-if="loggedin && !hasExpired()">
      <input  id="small_input" type="number" v-model="investmentAmount" placeholder="Investment amount" />ETH
      <button class="button" @click="invest(project.id)">Invest</button>
    </div>
    <p v-else>
      <p v-if="hasExpired()">This.project expired</p>
      <p v-if="hasExpired()">You can no longer invest in it.</p> <p v-if="!loggedin && !hasExpired()">Login to invest</p>
    </p>
    <button class="button" v-if="userAddr==project.owner && hasExpired() && hasReachedTarget &&!project.moneyTaken" @click="TransferMoney(project.id)">GET my money</button>
  </div>
  
</template>

<script lang="ts">
import { defineComponent, ref, computed } from 'vue';
import {BigNumber, Contract, ethers, providers} from 'ethers'
import {ProjectRegistry} from '../../typechain-types/ProjectRegistry'
import registryAdress from '../../projectRegistry.json'
import registryABI from '../../artifacts/contracts/ProjectRegistry.sol/ProjectRegistry.json'

interface Project {
  id: number;
  targetAmount: number;
  deadline: number;
  startTime: number;
  name: string;
  description: string;
  actualAmount: number;
  owner: string;
  backers: string[];
  moneyTaken:boolean;
}

export default defineComponent({
  name: 'ProjectCard',
  props: {
    project: {
      type: Object as () => Project,
      required: true,
    },
    loggedin: {
      type: Boolean,
      required: true,
    },
    userAddr:{
      type:String,
      required:true,
    },
    refresh: {
      type: Function,
      required: true,
    },
    
  },
  setup(props) {
    const deadline = new Date(props.project.deadline * 1000).toLocaleString();
    const hasExpired =()=>{ return new Date().getTime() >= props.project.deadline*1000};

    const hasReachedTarget = props.project.targetAmount<=props.project.actualAmount;

    let user: ethers.providers.JsonRpcSigner | null = null;
    let provider: ethers.providers.Web3Provider | null = null;
    const TransferMoney=async (id :number)=>{
      if(!user){initProvider(id,false);return}
      console.log("click");
      props.project.moneyTaken=true;
      const registryInstance = new Contract(registryAdress.address, registryABI.abi,user) as ProjectRegistry;
      const tx =await registryInstance.getMyMoney(id);
      tx.wait()
      const receipt = await tx.wait();
      props.refresh();
    }
    const initProvider=async (id:number,toi:boolean)=>
      {
        if(!user || !provider)
        {
          provider = new ethers.providers.Web3Provider((window as any).ethereum);
          user = provider.getSigner();
        }
        if(toi)
        {
        invest(id);
        }
        else
        {
          TransferMoney(id);
        }
      }
    
    const investmentAmount = ref(0.0);

    const invest = async (id:number) => {
      if(!user){initProvider(id,true);return}
      if(!isInvestmentAmountValid)
      {
        alert("weird funds");
        return;
      }
      const weiValue = ethers.utils.parseUnits(investmentAmount.value+"", "ether");
      //const funding =ethers.utils.parseEther(String(investmentAmount.value+""))
      //console.log(weiValue.toNumber())
      const registryInstance = new Contract(registryAdress.address, registryABI.abi,user) as ProjectRegistry;
      try {
        const tx =await registryInstance.invest(id,{value:weiValue });
        tx.wait()
        const receipt = await tx.wait();
        props.refresh();
      } catch (error) {
       alert("Something went wrong : "+error ) 
      }
    };

    const isInvestmentAmountValid = computed(() => {
      return investmentAmount.value > 0 && investmentAmount.value <= props.project.targetAmount;
    });

    return {
      deadline,
      hasExpired,
      hasReachedTarget,
      investmentAmount,
      invest,
      isInvestmentAmountValid,
      TransferMoney,
      
    };
  },
});
</script>

<style scoped>
.project-card {
  border: 1px solid #f2f2f2;
  border-radius: 5px;
  padding: 1rem;
  margin-bottom: 1rem;
}
progress  {
  background-color: #32a672;
}
h2{
  color:#32a672;
}
#owner{
  color: white;
}
#small_input
{
  width: 25%;
}
</style>
