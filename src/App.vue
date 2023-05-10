

<template>
  <div class="metamask-warning" v-show="!isMetamaskInstalled">
  <p>Pro použití této stránky potřebujete nainstalovat a aktivovat <a href="https://metamask.io">Metamask!</a></p>
  </div>
  <div id="top-menuu"><h1>Group-Founding/<br><span @click="login" v-show="loggedin">Login</span><span id="username">{{ userAddress }}</span></h1><div>&nbsp;</div><div class="menu-container"><div class="button" @click=showMenu>Filters</div><div class="menu" v-show=showedMenu >
    <div id="username">By Time</div>
    <button class="menu-button" :class="{ active: selectedFilter === 'running' }" @click="selectedFilter = 'running'">Running</button>
    <button class="menu-button" :class="{ active: selectedFilter === 'closed' }" @click="selectedFilter = 'closed'">Closed</button>
    <button class="menu-button" :class="{ active: selectedFilter === 'all' }" @click="selectedFilter = 'all'">All</button>
    <div id="username">By addr</div>
    <input type="text" id="ownerfilter" v-model="searched_addr" placeholder="adress">
    <button class="menu-button" :class="{ active: selectedFilterOwner === 'ByOwner' }" @click="selectedFilterOwner = 'ByOwner'">By Owner</button>
    <button v-show="!loggedin" class="menu-button" :class="{ active: selectedFilterOwner === 'FundedByMe' }" @click="selectedFilterOwner = 'FundedByMe'">Funded By Me</button>
    <button class="menu-button"  @click="selectedFilterOwner = 'none'" v-show="selectedFilterOwner!='none'">X</button>
    <div id="username">By Fundation</div>
    <button class="menu-button" :class="{ active: selectedFilterFunding === 'Funded' }" @click="selectedFilterFunding = 'Funded'">Funded</button>
    <button class="menu-button" :class="{ active: selectedFilterFunding === 'NotFunded' }" @click="selectedFilterFunding = 'NotFunded'">NotFunded</button>
    <button class="menu-button"  @click="selectedFilterFunding = 'none'" v-show="selectedFilterFunding!='none'">X</button>
  </div></div></div><br>
  <button v-show="!loggedin" @click="showModal = !showModal" class="button"><a href="#newproject" class="idn">Create new Project</a></button> 
    <CreateProject v-show="showModal" id="newproject" :refresh="refresh" :chngModal="chngModal"></CreateProject>
  <h3>Projects/[<span class="filtr" :class="{selectedfiltr: older==true}" @click=filterOlder>Older</span>|<span class="filtr" :class="{selectedfiltr: newer==true}" @click="filterNewer">Newer</span>]</h3>
    
  <div class="project-list">
    <div class="no-projects" v-if="empty">
      <div>0 projects <span id="username" @click="login" v-show="loggedin">Login and create One!</span></div>
    </div>
      <ProjectCard v-for="(project, index) in filteredProjects" :key="index" :project="project" :loggedin=!loggedin :userAddr="userAddress" :refresh="refresh" />           
    </div><br>
  
</template>

<script lang="ts">

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

import { defineComponent,ref,onMounted } from 'vue';
import {BigNumber, Contract, ethers, providers} from 'ethers'
import ProjectCard from './components/ProjectCard.vue';
import CreateProject from './components/CreateProject.vue';

import {ProjectRegistry} from '../typechain-types/ProjectRegistry'
import registryAdress from '../projectRegistry.json'
import registryABI from '../artifacts/contracts/ProjectRegistry.sol/ProjectRegistry.json'

onMounted(() => {
  
})

export default defineComponent(
  {
    components: {
    ProjectCard,
    CreateProject,
  },
  data()
  {
    return {
      isMetamaskInstalled: false,
    };
  },
  computed: {
    filteredProjects() {
  let projectsToShow = [] as Project[];
  if (this.selectedFilter === 'all') {
    projectsToShow = this.projects;
  } else if (this.selectedFilter === 'running') {
    projectsToShow = this.projects.filter((project) => {
      return project.deadline > Date.now() / 1000 && project.actualAmount < project.targetAmount;
    });
  } else if (this.selectedFilter === 'closed') {
    projectsToShow = this.projects.filter((project) => {
      return project.deadline <= Date.now() / 1000 ;
    });
  }

  if(this.selectedFilterFunding==='Funded')
  {
    projectsToShow=projectsToShow.filter((project) => {
      return project.actualAmount >= project.targetAmount;
    });
  }
  else if(this.selectedFilterFunding==='NotFunded')
  {
    projectsToShow=projectsToShow.filter((project) => {
      return project.actualAmount < project.targetAmount;
    });
  }
  if(this.selectedFilterOwner=== 'FundedByMe')
  {
    projectsToShow = projectsToShow.filter((project) => {
  if (!project.backers) {
    return false;
  }

  
  return project.backers.some(backer => backer === this.userAddress);
});
  }
  if(this.selectedFilterOwner==='OwnedbyMe')
  {
      projectsToShow=projectsToShow.filter((project) => {
      return project.owner ==this.userAddress;
    });
    
  }
  else if(this.selectedFilterOwner==='ByOwner')
  {
    
    if(this.searched_addr.length==42)
    {
      
      projectsToShow=projectsToShow.filter((project) => {
      return project.owner ==this.searched_addr;
    });
    }
    else
    {
      alert('Wrong address format');
      this.selectedFilterOwner='none';
    }
  
  }
  if(projectsToShow.length==0)
  {
    this.empty=true;
  }
  else
  {
    this.empty=false;
  }
  if(this.newer)
  {
    projectsToShow.sort((a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime());
    return projectsToShow;
  }
  else
  {
    projectsToShow.sort((a, b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime());
    return projectsToShow;
  }
}},
  mounted() {
    if ((window as any).ethereum) {
      this.isMetamaskInstalled = true;
    }
    this.login();
    
  },
    setup()
    {
      const empty=ref(false);
      const showedMenu=ref(false)
      const selectedFilter=ref('all')
      const selectedFilterFunding=ref('none')
      const selectedFilterOwner=ref('none')
      const userAddress =ref('')
      const  userBalance=ref('');
      const searched_addr=ref('');
      const loggedin=ref(true);
      const older=ref(false);
      const newer=ref(true);
      const showModal = ref(false);
      

      let user: ethers.providers.JsonRpcSigner |null =null;
      let provider :ethers.providers.Web3Provider;
      const projects: Project[] = [];

    const refresh=()=>{
      initRegistry();
    }
    const filterOlder=()=>{
      older.value=true;
      newer.value=false;
    }
    const filterNewer=()=>{
      older.value=false;
      newer.value=true;
    }

    const showMenu=()=>{
      showedMenu.value=!showedMenu.value;
    }
    const initRegistry=async ()=>{
      if(!provider)
      {
        provider=new ethers.providers.Web3Provider((window as any).ethereum);
      }
      console.log(projects.values.length);
      while (projects.length > 0) {
        projects.splice(0, 1);
      }

      console.log(projects.length);
      const registryInstance = new Contract(registryAdress.address, registryABI.abi,provider) as ProjectRegistry;
      const projectCount = await registryInstance.getProjectCount();
      console.log(projectCount.toNumber());
      for (let i = 0; i < projectCount.toNumber(); i++) {
        const project = await registryInstance.getProject(i);
        const valueInWei = project[5];
        const valueInEther = ethers.utils.formatEther(valueInWei);
        const valueAsNumber = parseFloat(valueInEther);
        const valueInEtherTarget = ethers.utils.formatEther(project[3]);
        const valueAsNumberTarget = parseFloat(valueInEtherTarget);
        projects.push({
          id: project[7].toNumber(),
          name: project[0],
          description: project[1],
          owner: project[2],
          targetAmount: valueAsNumberTarget,
          deadline: project[4].toNumber(),
          actualAmount: valueAsNumber ,
          backers: project[6],
          startTime:project[9].toNumber(),
          moneyTaken:project[8],
        });
      }
      selectedFilter.value='closed';
      selectedFilter.value='all';
      console.log(projects);
      if(projects.length==0)
      {
        empty.value=true;
      }
      else
      {
        empty.value=false;
      }
    }
    
    
    const login= async ()=>{
      if(!('ethereum' in window ))
      {
        return;
      }
      (window as any).ethereum.enable()
      loggedin.value=false;
      
      user = provider.getSigner();
      userAddress.value =await user.getAddress();
      const balance =await provider.getBalance(userAddress.value);
      userBalance.value=ethers.utils.formatEther(balance);
      (window as any).ethereum.on('accountsChanged',function(){
      console.log("changed");
      changedacc();
      });

      const changedacc= async () =>{
        user = provider.getSigner();
        userAddress.value= await user.getAddress();
      }
      
    }
    const chngModal=()=>
    {
      showModal.value=!showModal.value;
    }
    refresh();
    return {
        login,userAddress, userBalance
        ,projects,showMenu,selectedFilter,showedMenu,searched_addr,loggedin,older,chngModal,
        newer,filterOlder,filterNewer,selectedFilterOwner,selectedFilterFunding,showModal,refresh,empty
    }
  }
  }
);
</script>

<style scoped>
header {
  line-height: 1.5;
}
#top-menuu{
  display: flex;
  justify-content: space-between;
}
.logo {
  display: block;
  margin: 0 auto 2rem;
}
.menu-container {
  position: relative;
}

.menu {
  position: absolute;
  top: 100%;
  left: -100px;
  z-index: 1;
  display: flex;
  flex-direction: column;
  background-color: #fff;
  border: 1px solid #ddd;
  border-radius: 4px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  padding: 0.5rem;
  min-width: 120px;
}

.menu-button {
  padding: 0.5rem;
  border: none;
  background-color: transparent;
  cursor: pointer;
}

.menu-button.active {
  background-color: #41B883;
  color: #fff;
}

.metamask-warning {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.8);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
}

.metamask-warning p {
  font-size: 24px;
  color: white;
  text-align: center;
}
.no-projects {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 66vh; /* nastaví výšku na 2/3 výšky obrazovky */
  width: 100%;
 
}

</style>
