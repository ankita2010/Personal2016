/******************************************************************************************************************************************
 * Copyright by Autodesk, Inc.
 * 
 * The information contained herein is confidential, proprietary to
 * Autodesk, Inc., and considered a trade secret as defined in section
 * 499C of the penal code of the State of California. Use of
 * this information by anyone other than authorized employees of 
 * Autodesk, Inc. is granted only under a written non-disclosure
 * agreement, expressly prescribing the scope and manner of such use.
 * 
 * $Id$             =  EMS_TransactionUtlity 
 * $Created Date$   =  23-April-2016
 * $Author$         =  Ankita Nair
 * $Description$    =  This is a utility class for ADSK_MergeContractsRestService
 ******************************************************************************************************************************************/

public class EMS_TransactionUtlity {
    
    public static Map<String, Service_Contract_Resellers__c> survivorResellers = new Map<String, Service_Contract_Resellers__c>();
   
   
    
    /**
    * @description - This method returns list of non existing/matching Asset standard records, these will be inserted on survivor agreement
    * @param - Map <Id,Asset>,Set<Id>,ServiceContract
    * @return - List<Asset> 
    */
    public static List<Asset> returnAssetStdList(Map<Id, Asset> prodIdAndAsset, Set<Id> survivorStdAssetProdId,String survivorRecId){
        List<ServiceContract> servContractList  =  new List<ServiceContract>();
        Map<String,Asset> assetsToCreate = new Map<String,Asset>();
       // List<Asset> assetsToCreate = new List<Asset> ();
        servContractList   = [Select id,Name from ServiceContract where id=: survivorRecId];
        for(Id prodId : prodIdAndAsset.keySet()){//iterating over dummy prod ID of victim Asset std.
            if(!survivorStdAssetProdId.contains(prodId)){//If survivor is not having Asset std based on Dummy Prod Id, add it in list
                Asset tmpAstStd = new Asset();
                tmpAstStd = prodIdAndAsset.get(prodId).clone();
                tmpAstStd.Service_Contract__c = survivorRecId;
                tmpAstStd.Name = servContractList[0].Name;
                System.debug('tmpAstStd ' + tmpAstStd);
                assetsToCreate.put(tmpAstStd.Product2Id,tmpAstStd);
                
            }
        }
        return assetsToCreate.values();
    }
    
    /**
    * @description - This method returns list of non existing/matching CLI records, these will be inserted on survivor agreement
    * @param - List<ContractLineItem>,Map<String, Id> 
    * @return - List<ContractLineItem> 
    */
    
     public static List<ContractLineItem> returnCLIList (List<ContractLineItem> CLIToCopy, Map<String, Id> entNameAndIdMap, String survivrContractId){
        Map<String, ContractLineItem> victimCLIs = new Map<String, ContractLineItem>();
        Map<String, ContractLineItem> survivorCLIs = new Map<String, ContractLineItem>();
        List<ContractLineItem> cliListToReturn = new List<ContractLineItem>();
        for(ContractLineItem cli : CLIToCopy){
            String cliKey = cli.Entitlement__r.Name + '_' + cli.Asset__c;
            if (cli.ServiceContractId != survivrContractId){
                victimCLIs.put(cliKey, cli); // collect all victim data
            } else {
                survivorCLIs.put(cliKey, cli);
            }
        }
        for(String cliKey : victimCLIs.keySet()){
            ContractLineItem CLIInst = new ContractLineItem ();
            if(!victimCLIs.get(cliKey).Status.equalsIgnoreCase('Expired') && !survivorCLIs.containsKey(cliKey)){ //Expired CLIs should not be copied
                CLIInst = victimCLIs.get(cliKey).clone();
                CLIInst.Entitlement__c = entNameAndIdMap.get(victimCLIs.get(cliKey).Entitlement__r.Name);
                CLIInst.ServiceContractId = survivrContractId;
                CLIInst.Integration_Status__c = Label.EMS_Transaction_Queued;
                //To avoid CLI date issue (as trigger would add 30 days grace period), we are using Actual_End_Date__c
                CLIInst.EndDate = victimCLIs.get(cliKey).Actual_End_Date__c;
                cliListToReturn.add(CLIInst);
            }
        }
        return cliListToReturn;
    }
    
    /**
    * @description - This method returns list of non existing/matching ECC records, these will be inserted on survivor agreement
    * @param - LList<Entitlement_Contacts_Custom__c> ,Map<String, Id>
    * @return - List<Entitlement_Contacts_Custom__c>
    */
    
    public static List<Entitlement_Contacts_Custom__c> returnECCList (List<Entitlement_Contacts_Custom__c> ECCToCopy,Map<String,String> entNameAndIdMap, String survivorRecId){
        Map<String, String> ECCMap = new Map<String, String> ();
       // Map<String,Entitlement_Contacts_Custom__c> ECCToReturn = new Map<String,Entitlement_Contacts_Custom__c>();
       List<Entitlement_Contacts_Custom__c> ECCToReturn = new List<Entitlement_Contacts_Custom__c>();
       // List<Entitlement_Contacts_Custom__c> ECCToReturn = new List<Entitlement_Contacts_Custom__c> ();
        system.debug('ECCToCopy'+ECCToCopy);
        for(Entitlement_Contacts_Custom__c ecc : ECCToCopy){   
            String eccKey = ecc.Entitlement__r.Name + '_' + ecc.Contact__c;
            if(ecc.Entitlement__r.ServiceContractId == survivorRecId){
                ECCMap.put(eccKey, 'dontCreate');
            } else if(!ECCMap.containsKey(eccKey)){
                ECCMap.put(eccKey, 'create');
                System.debug('eccMap-----'+ECCMap);
                System.debug('eccMap-----'+ECCMap2);
            }
        }
        for(Entitlement_Contacts_Custom__c ecc : ECCToCopy){
            String eccKey = ecc.Entitlement__r.Name + '_' + ecc.Contact__c;
            system.debug('ecckey'+ecckey);
            if(ECCMap.get(eccKey) != null && ECCMap.get(eccKey).equalsIgnoreCase('create')){
                Entitlement_Contacts_Custom__c ECCInst = new Entitlement_Contacts_Custom__c ();
                ECCInst = ecc.clone();
                ECCInst.Entitlement__c = entNameAndIdMap.get(ECCInst.Entitlement__r.Name);
                ECCInst.Contact__c = ecc.Contact__c;
                ECCInst.Integration_Status__c = Label.EMS_Transaction_Queued;
                system.debug('ECCInst'+ECCInst);
                //ECCToReturn.put(ECCInst.Entitlement__c,ECCInst);
                ECCToReturn.add(ECCInst);
                system.debug('ECCToReturn'+ECCToReturn);
               
            }
        }
        return ECCToReturn;
    }
    
    /**
    * @description - This methods returns non existing (for survivor agreement) SCR records
    * @param - List<Service_Contract_Resellers__c>
    * @return - List<Service_Contract_Resellers__c>
    */
    
    public static List<Service_Contract_Resellers__c> returnSCRList (List<Service_Contract_Resellers__c> SCRListToCopy ,String survivorRecId){
        List<Service_Contract_Resellers__c> SCRListToReturn = new List<Service_Contract_Resellers__c> ();
        Map<String, Service_Contract_Resellers__c> victimResellers = new Map<String, Service_Contract_Resellers__c> ();

        for(Service_Contract_Resellers__c scr : SCRListToCopy){
            String tmpKey = scr.Reseller_Id__c;
            if(scr.Agreement_Id__c != survivorRecId){
                victimResellers.put(tmpKey, scr);
                system.debug('victimResellers'+victimResellers);
            } else {
                survivorResellers.put(tmpKey, scr);
            }
        }
        for(String accId : victimResellers.keySet()){
            Service_Contract_Resellers__c tmpInst = new Service_Contract_Resellers__c ();
            if(!survivorResellers.containsKey(accId)){//Victim SCR's should be copied to Survivor 
                tmpInst = victimResellers.get(accId).clone();
                tmpInst.Agreement_Id__c = survivorRecId;
                SCRListToReturn.add(tmpInst);
                system.debug('SCRListToReturn'+SCRListToReturn);
            }
        }
        return SCRListToReturn;
    }
     /**
    * @description - This methods returns SCR records based on sold to CSN of service contract
    * @param - List<Account>
    * @return - List<Service_Contract_Resellers__c>
    */
   
    public static List<Service_Contract_Resellers__c> returnSCRSoldToList (List<Account> accountListToCreateSCR,String survivorRecId){
        List<Service_Contract_Resellers__c> SCRListToReturn = new List<Service_Contract_Resellers__c> ();
        for(Account acc : accountListToCreateSCR){
            Service_Contract_Resellers__c tmpInst = new Service_Contract_Resellers__c ();
            system.debug('survivorResellers::'+survivorResellers);
            if(!survivorResellers.containsKey(acc.Id)){
                tmpInst.Reseller_Id__c = acc.Id;
                tmpInst.Agreement_Id__c = survivorRecId;
                SCRListToReturn.add(tmpInst);
                system.debug('SCRListToReturn'+SCRListToReturn);
            }
        }
        return SCRListToReturn;
    }
    /**
    * @description - This methods end dates existing victim contract's Date as Yesterday
    * @param - void
    * @return - void
    */
      public static String endDateVictimAgreement (String survivorRecId,List<Id> mergeableIds){
        String log;
        List<ServiceContract> victimSCEndDate = new List<ServiceContract> ();
        for(ServiceContract scTemp : [Select Id,EndDate,Force_End_date__c from ServiceContract where id in: mergeableIds]){
            if(scTemp.Id != survivorRecId){
                ServiceContract sc = new ServiceContract();
                sc.Id = scTemp.Id;
                sc.EndDate = System.today()-1;
                sc.Force_End_date__c = true;
                sc.Integration_Status__c = Label.EMS_Transaction_Queued;
                victimSCEndDate.add(sc);
                system.debug('Force End Date'+ sc.Force_End_date__c);
            }
         }
         try{
             if(!victimSCEndDate.isEmpty()){
                 update victimSCEndDate;//DML on Contract object (end dating)
                 log = '\r\n' + System.now() + ' Victim ServiceContract(s) is End Dated';
              }
          }
          catch(Exception e){
                log = '\r\n' + System.now() + ' Exception occurred while end dating Victim Service Contract(s): ' + e.getMessage();
                ADSK_MergeContractsRestService.errorObject = Schema.sObjectType.ServiceContract.getLabel();
                System.debug('The following exception has occurred: ' + e.getMessage());
                
            }
            return log;
      }
    
     /**
    * @description - This methods end dates existing victim contract line items Date to Yesterday
    * @param - List<ContractLineItem>,Set<Id>
    * @return - void
    */
     
    public static String endDateVictimCLIs (List<ContractLineItem> CLIsToCopy, Set<Id> newCLIIDs,String survivorRecId){
        String victimlog;
        System.debug('endDateVictimCLIsMethodCalled ' + CLIsToCopy.size());
        List<ContractLineItem> CLIsToEndDate = new List<ContractLineItem> ();
        for(ContractLineItem cli : CLIsToCopy){
            if(cli.ServiceContractId != survivorRecId){
                ContractLineItem cliInst = new ContractLineItem ();
                cliInst.Id = cli.Id;
                cliInst.EndDate = System.today()-1;
                cliInst.Actual_End_Date__c = System.today() -1;
                cliInst.Force_End_date__c=true;
                cliInst.Integration_Status__c = Label.EMS_Transaction_Queued;
                cliInst.Comments__c = cliInst.Comments__c != null? cliInst.Comments__c += 'Contract Merge' : cliInst.Comments__c;
                System.debug('cliInst.Force_End_date__c'+cliInst.Force_End_date__c);
                CLIsToEndDate.add(cliInst);
            }
        }
        try {
            if(!CLIsToEndDate.isEmpty()){
                update CLIsToEndDate;//DML on CLI object (end dating)
                victimlog = '\r\n' + System.now() + ' Victim CLIs were end Dated ';
            }
        } catch (DMLException e){
            ADSK_MergeContractsRestService.errorObject = Schema.sObjectType.ContractLineItem.getLabel();
            system.debug('errorObject'+ADSK_MergeContractsRestService.errorObject);
            victimlog = '\r\n' + System.now() + ' Exception occurred while end dating CLI records: ' + e.getMessage();
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return victimlog;
    }
    
    /**
    * @description - This methods end dates existing victim ECC's Date to Yesterday
    * @param - List<Entitlement_Contacts_Custom__c> ECCToCopy,String
    * @return - void
    */
     
    public static String endDateVictimECCs (List<Entitlement_Contacts_Custom__c> ECCToCopy,String survivorRecId){
        String eccLog;
        List<Entitlement_Contacts_Custom__c> ECCsToEndDate = new List<Entitlement_Contacts_Custom__c> ();
        for(Entitlement_Contacts_Custom__c ecc : ECCToCopy){
            if(ecc.Entitlement__r.ServiceContractId != survivorRecId){
                Entitlement_Contacts_Custom__c eccInst = new Entitlement_Contacts_Custom__c ();
                eccInst.Id = ecc.Id;
                eccInst.End_Date__c = System.today()-1;
                eccInst.Integration_Status__c = Label.EMS_Transaction_Queued;
                ECCsToEndDate.add(eccInst);
            }
        }
        try {
            if(!ECCsToEndDate.isEmpty()){
                update ECCsToEndDate;//DML on ECC object (end dating)
                eccLog = '\r\n' + System.now() + ' Victim ECC(s) is End Dated.' ;
            }
        } catch (DMLException e){
            ADSK_MergeContractsRestService.errorObject = Schema.sObjectType.Entitlement_Contacts_Custom__c.getLabel();
            eccLog = '\r\n' + System.now() + ' Exception occurred while end dating ECC record(s): ' + e.getMessage();
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return eccLog;
    }
    
}