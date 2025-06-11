graph TD
    subgraph GitHub (external)
        GH[GitHub Repo<br/>(wiztasky source)]
    end

    GH --> ACRDeploy[Push image to ACR]

    subgraph Resource Group: wiz-test-rg
        subgraph Virtual Network
            ACR[Azure Container Registry<br/>(wiztaskyacr)]
            AKS[AKS Cluster<br/>(wiz-aks-cluster)]
            LB[LoadBalancer Service<br/>Public IP: 135.237.61.107]
            Mongo[MongoDB VM<br/>51.8.117.117]
            Blob[Azure Blob Storage<br/>(wizstorage...)]
        end
    end

    ACRDeploy --> ACR
    ACR --> AKS
    AKS --> LB
    AKS --> Mongo
    AKS --> Blob
