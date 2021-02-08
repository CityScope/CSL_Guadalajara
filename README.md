# CSL_Guadalajara
Repository for the CityScope project related to Guadalajara Collaboration

# Installation
  - Clone this reposetory
  - Download GAMA (compatible with GAMA 1.8) [here](https://gama-platform.github.io/download)
  - Run GAMA, 
  - Choose a new Workspace (this is a temporay folder used for computation)
  - right click on User Models->Import->GAMA Project..
  - Select SocialFabric_CS in the CSL_Guadalajara folder that you have clone


# Context

Fear prevents the use of public spaces, which can be attributed to the way cities are perceived and designed. Although there is a certain component of spatial determinism, it is ultimately defined by the relationship between the physical configuration of the space and the social use made of it as well as a confluence of political, economical and behavioural factors.  

In the search to determine the patterns that highlights fear perception in public spaces, it is proposed as initial approach a mechanism to construct composite indicators, using multi-criteria analysis and ranked weights, which is based in the scrutiny of literature linked to safer and more inclusive spaces between 1980 and 2020 with three different approaches; (1) environmental crimonology, system analysis and behavioural sciences, (2) urban planning and (3) architecture and social sciences. A branch of this last one addresses gender mainstreaming as a positive approach to cope with current global urban challenges, such as rapid urbanisation and migration.

Since quantification and numerical data are not enough to understand this reality, it has been essential evaluating the indicators from the proximity of the community scale thus the quality and accuracy of these indicators have been evolved with the feedback on the empirical processes, from focus groups workshops to in-depth personal interviews with women involved in the specific community of study, checking whether the set of individual indicators based on the academic papers is sufficient or appropriate to describe the phenomenon. 

#### Since the perception of insecurity is completly linked to the person, depending on how familar you are with the context or how much you have normalized certain types of violence, the model aims not to lose the proximity when both understanding the phenomenon and conveying the results. Consequently, the simulation works with the indicators described and shows the perception of insecurity of each of the agents depending on how they interact with each other and with these variables in the specific context of Lomas del Centinela, Guadalajara.

Google Doc Kick Off Document
https://docs.google.com/document/d/1pGR2nZAFjOmYgx4lRgj9_hp9zRQZjznpVr-no6Qlsls/edit?ts=5c1a59e6

# Blockchain-based vaccine distribution

HOLA

The current pandemic caused by the SARS-COV2 coronavirus has forced scientists and manufacturers to develop an effective vaccine within an unprecedentedly short time. This may be considered the most important health challenge that humanity has faced over the past decades. Furthermore, as they become available, they need to be distributed around the world safely and hopefully equitably through different supply chains. However, pharmaceutical supply chains may face serious problems such as bureaucracy, counterfeiting of medicines, or the hoarding of these by countries with stronger economies. Unlike other supply chains, a mistake in the pharmaceutical supply chain can cause serious health problems for people. As a measure to address some of these issues we propose a Smart Contract Blockchain Architecture based on a Ethereum's private network and an agent based model for the distribution and application of the COVID-19 vaccine. This work includes a methodology and a cloud-based architecture pattern for the deployment of the proposed Blockchain solution that is evaluated in the agent model. Under the proposed methodology, both the Blockchain solution and the agent-based model can be adapted to the vaccination programs of each country. For the proposal we consider one of the three pillars of the Access to COVID-19 Tools (ACT) Accelerator from the World Health Organization known as COVAX. This initiative seeks the safe and equitable distribution of COVID-19 vaccines to all of the more than 170 participating countries. For the application of the vaccine, the model takes into account characteristics of the people such as age, comorbidity and time of immunity after recovery. Based on this, a prioritization scheme is explored in which each vaccination event is recorded in the Blockchain along with the personal data related to the person who is being immunized. Whereas for the supply chain, a transport travels through the places in the supply chain. The data of shipments and receptions of vaccines are stored in the Blockchain for each place visited. It is expected that based on the characteristics of Blockchain such as immutability, transparency, consensus and decentralization, greater trust and a safe distribution and application of the vaccine can be achieved under the objectives of the COVAX initiative. Simulation results showed that the transactions on the Blockchain network were consistent with those associated and configured events related to the distribution and application of the vaccines in 100% in the Agent Based Model Platform, meaning that the proposed Blockchain Architecture is suitable for addressing the COVID-19  vaccination challenges previously described.

    • Download and install Node.js here https://nodejs.org/es/
    • Download Ganache (Ethereum Network) here https://www.trufflesuite.com/ganache
    • Download GAMA here https://gama-platform.github.io/
    • Install solidity using a terminal with the command npm install -g solc
    • Install web3.py with the command pip install web3
    • Install truffle with the command npm install -g truffle
    • Clone this repository
    • Open Ganache → Click on new workspace→ Assign a name to the ethereum network → Click on save workspace
    • Open the project 
    • Enter the project in the constracts folder through a terminal
    • Execute the command truffle compile
    • Execute the command truffle migrate
    • In ganache, click on contracts, copy the addresses of the contracts
    • Open the file prueba.py and paste the addresses (In the shipping_contracts function, paste the address of the vaccine contract, in the reception_contract function paste         the reception contract address, and in the application_contract function paste the Application contract address)
    • Run GAMA
    • Choose a new workspace
    • right click on User Models->Import->GAMA Project.
    • Select Blockchain-based vaccine distribution in the CSL_Guadalajara folder that you have clone
    • Run the connection.py file
    • Run the model in GAMA
