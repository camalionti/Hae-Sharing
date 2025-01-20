/**
* @author CloudLoop
* @date August 2023
*
* @description Batch process that updates shares for accounts
*/
public class CL_UpdateShareBatch implements Database.Batchable<sObject>, Database.stateful {
    
    private static final String TYPE_BATCH = 'Apex Batch';
    private static final String AUTOMATION_NAME = 'CL_UpdateShareBatch';
    private static final String DEFAULT_ERROR_MESSAGE = 'Something went wrong.';
    private String errorMessage;
    public CL_UpdateShareBatch() {
    }

    public Database.QueryLocator start(Database.BatchableContext bc){  
         Id thisJobId = bc.getJobId();
        List<AsyncApexJob> lstJobs = [SELECT Id FROM  AsyncApexJob
                             WHERE status ='Processing' AND ApexClass.Name = 'CL_UpdateShareBatch' AND id!=:thisJobId];

        if(!lstJobs.IsEmpty())
        {
            return Database.getQueryLocator('SELECT Id, ParentId, Name from Account limit 0');
        }
    	return Database.getQueryLocator('SELECT Id, ParentId, Name from Account where Update_Shares__c = true');

    }

    public void execute(Database.BatchableContext bc, List<Account> scope){
        Set<Id> parentIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<ID,ID> accountToParentMAp = new Map<ID,ID>();
        for (Account a : scope) {
            a.Update_Shares__c = false;
            if (a.ParentId != null) {
                parentIds.add(a.ParentId);
                accountToParentMap.put(a.Id, a.PArentId);
            }
            accountIds.add(a.Id);
        }
        List<AccountContactRelation> accountContactRelationList = new List<AccountContactRelation>([
            SELECT Id, accountid, contactid from AccountContactRelation where accountId in :parentIds]);
        Set<ID> contactIds = new set<Id>();
        for (AccountContactRelation acr : accountContactRelationList) {
            contactIds.add(acr.ContactId);
        }
        List<User> userList = new List<user>([select id, contactid from User where contactid IN :contactIds]);
        Map<Id, Id> contactToUserMap = new Map<Id, Id>();
        for (User u : userList) {
            contactToUserMap.put(u.ContactId, u.Id);
        }
        Map<ID,Set<ID>> accountToUserMap = new Map<ID,Set<ID>>();
        for(AccountContactRelation acr: accountContactRelationList)
        { 
            if (contactToUserMap.containsKey(acr.ContactId)) {
                if (!accountToUserMap.containsKey(acr.accountId)) {
                    accountToUserMap.put(acr.accountId, new Set<Id>());
                }
                accountToUserMap.get(acr.accountId).add(contactToUserMap.get(acr.ContactId));
            }
        }
         List<AccountShare> accountSharesToCreate = new List<AccountShare>(); 
         for(Account a : scope) { 
             if (accountToParentMap.containsKey(a.Id)) {
                 Id parentId = accountToParentMap.get(a.Id);
                 if (accountToUserMap.containsKey(parentId)) {
                     for (Id userId : accountToUserMap.get(parentId)) {
                        AccountShare accountShare = new AccountShare(); 
                        accountShare.AccountId = a.Id; 
                        accountShare.UserOrGroupId = userId;
                        accountShare.RowCause = 'Manual';
                        accountShare.AccountAccessLevel = 'edit';
                        accountShare.OpportunityAccessLevel = 'None';
                        accountSharesToCreate.add(accountShare); 
                     }
                 }
             }
         } 
         if (!accountSharesToCreate.isEmpty())
            Database.insert(accountSharesToCreate, false);

         // Process cases
         
        List<Case> caseList = new List<Case>([select id, accountId from Case where accountId IN :accountIds]);
        Map<ID,Set<ID>> accountToCaseMap = new Map<ID,Set<ID>>();
        for(Case c : caseList)
        { 
            if (!accountToCaseMap.containsKey(c.accountId)) {
                accountToCaseMap.put(c.accountId, new Set<Id>());
            }
            accountToCaseMap.get(c.accountId).add(c.Id);
        }
        
         List<CaseShare> caseSharesToCreate = new List<CaseShare>(); 
         for(Account a : scope) { 
             if (accountToParentMap.containsKey(a.Id)) {
                 Id parentId = accountToParentMap.get(a.Id);
                 if (accountToUserMap.containsKey(parentId) && 
                 accountToCaseMap.containsKey(a.Id)) {
                     for (Id userId : accountToUserMap.get(parentId)) {
                         for (Id caseId : accountToCaseMap.get(a.Id)) {
                            CaseShare caseShare = new CaseShare(); 
                            caseShare.CaseId = caseId; 
                            caseShare.UserOrGroupId = userId;
                            caseShare.RowCause = 'Manual';
                            caseShare.CaseAccessLevel = 'edit';
                            caseSharesToCreate.add(caseShare); 
                         }
                     }
                 }
             }
         } 
         if (!caseSharesToCreate.isEmpty())
            Database.insert(caseSharesToCreate, false);
        
         // Process Assets
         
        List<Asset> assetList = new List<Asset>([select id, accountId from Asset where accountId IN :accountIds]);
        Map<ID,Set<ID>> accountToAssetMap = new Map<ID,Set<ID>>();
        for(Asset c : assetList)
        { 
            if (!accountToAssetMap.containsKey(c.accountId)) {
                accountToAssetMap.put(c.accountId, new Set<Id>());
            }
            accountToAssetMap.get(c.accountId).add(c.Id);
        }
        
         List<AssetShare> assetSharesToCreate = new List<AssetShare>(); 
         for(Account a : scope) { 
             if (accountToParentMap.containsKey(a.Id)) {
                 Id parentId = accountToParentMap.get(a.Id);
                 if (accountToUserMap.containsKey(parentId) && 
                 accountToAssetMap.containsKey(a.Id)) {
                     for (Id userId : accountToUserMap.get(parentId)) {
                         for (Id assetId : accountToAssetMap.get(a.Id)) {
                            AssetShare assetShare = new AssetShare(); 
                            assetShare.AssetId = assetId; 
                            assetShare.UserOrGroupId = userId;
                            assetShare.RowCause = 'Manual';
                            assetShare.AssetAccessLevel = 'edit';
                            assetSharesToCreate.add(assetShare); 
                         }
                     }
                 }
             }
         } 
         if (!assetSharesToCreate.isEmpty())
            Database.insert(assetSharesToCreate, false);
        
        // Process ServiceAppointments
         
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>([select id, accountId from ServiceAppointment where accountId IN :accountIds]);
        Map<ID,Set<ID>> accountToServiceAppointmentMap = new Map<ID,Set<ID>>();
        for(ServiceAppointment c : serviceAppointmentList)
        { 
            if (!accountToServiceAppointmentMap.containsKey(c.accountId)) {
                accountToServiceAppointmentMap.put(c.accountId, new Set<Id>());
            }
            accountToServiceAppointmentMap.get(c.accountId).add(c.Id);
        }
        
         List<ServiceAppointmentShare> serviceAppointmentSharesToCreate = new List<ServiceAppointmentShare>(); 
         for(Account a : scope) { 
             if (accountToParentMap.containsKey(a.Id)) {
                 Id parentId = accountToParentMap.get(a.Id);
                 if (accountToUserMap.containsKey(parentId) && 
                 accountToServiceAppointmentMap.containsKey(a.Id)) {
                     for (Id userId : accountToUserMap.get(parentId)) {
                         for (Id ServiceAppointmentId : accountToServiceAppointmentMap.get(a.Id)) {
                            ServiceAppointmentShare serviceAppointmentShare = new ServiceAppointmentShare(); 
                            serviceAppointmentShare.ParentId = ServiceAppointmentId; 
                            serviceAppointmentShare.UserOrGroupId = userId;
                            serviceAppointmentShare.RowCause = 'Manual';
                            serviceAppointmentShare.AccessLevel = 'edit';
                            serviceAppointmentSharesToCreate.add(serviceAppointmentShare); 
                         }
                     }
                 }
             }
         } 
         if (!serviceAppointmentSharesToCreate.isEmpty())
            Database.insert(serviceAppointmentSharesToCreate, false);

            // Process Order
         
        List<Order__c> orderList = new List<Order__c>([select id, bill_to_account__c, ship_to_account__c
         from Order__c where bill_to_account__c IN :accountIds or ship_to_account__c in :accountIds]);
        Map<ID,Set<ID>> accountToOrderMap = new Map<ID,Set<ID>>();
        for(Order__c c : orderList)
        { 
            if (c.bill_to_account__c != null && !accountToOrderMap.containsKey(c.bill_to_account__c)) {
                accountToOrderMap.put(c.bill_to_account__c, new Set<Id>());
            }
            if (c.ship_to_account__c != null && !accountToOrderMap.containsKey(c.ship_to_account__c)) {
                accountToOrderMap.put(c.ship_to_account__c, new Set<Id>());
            }
            if (c.bill_to_account__c != null)
                accountToOrderMap.get(c.bill_to_account__c).add(c.Id);
            if (c.ship_to_account__c != null)
                accountToOrderMap.get(c.bill_to_account__c).add(c.Id);
        }
        
         List<Order__Share> orderSharesToCreate = new List<Order__Share>(); 
         for(Account a : scope) { 
             if (accountToParentMap.containsKey(a.Id)) {
                 Id parentId = accountToParentMap.get(a.Id);
                 if (accountToUserMap.containsKey(parentId) && 
                 accountToOrderMap.containsKey(a.Id)) {
                     for (Id userId : accountToUserMap.get(parentId)) {
                         for (Id orderId : accountToOrderMap.get(a.Id)) {
                            Order__Share orderShare = new Order__Share(); 
                            orderShare.ParentId = orderId; 
                            orderShare.UserOrGroupId = userId;
                            orderShare.RowCause = 'Manual';
                            orderShare.AccessLevel = 'edit';
                            orderSharesToCreate.add(orderShare); 
                         }
                     }
                 }
             }
         } 
         if (!orderSharesToCreate.isEmpty())
            Database.insert(orderSharesToCreate, false);

        Database.update(scope, false);
    }
    
    public void finish(Database.BatchableContext bc){
    	Database.executeBatch(new CL_DeleteShareBatch(), 10);
    }
}