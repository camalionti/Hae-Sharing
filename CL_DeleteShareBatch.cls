/**
* @author CloudLoop
* @date August 2023
*
* @description Batch process that updates shares for accounts
*/
public class CL_DeleteShareBatch implements Database.Batchable<sObject>, Database.stateful {
    
    private static final String TYPE_BATCH = 'Apex Batch';
    private static final String AUTOMATION_NAME = 'CL_DeleteShareBatch';
    private static final String DEFAULT_ERROR_MESSAGE = 'Something went wrong.';
    private String errorMessage;
    public CL_DeleteShareBatch() {
    }

    public Database.QueryLocator start(Database.BatchableContext bc){   
         Id thisJobId = bc.getJobId();
        List<AsyncApexJob> lstJobs = [SELECT Id FROM  AsyncApexJob
                             WHERE status ='Processing' AND ApexClass.Name = 'CL_DeleteShareBatch' AND id!=:thisJobId];

        if(!lstJobs.IsEmpty())
        {
            return Database.getQueryLocator('SELECT Id, ParentId, Name from Account limit 0');
        }
    	return Database.getQueryLocator('SELECT Id, Name from Account where Delete_Shares__c = true');

    }

    public void execute(Database.BatchableContext bc, List<Account> scope){
        Set<Id> accountIds = new Set<Id>();
        for (Account a : scope) {
            a.Delete_Shares__c = false;
            accountIds.add(a.Id);
        }
        List<AccountContactRelation> accountContactRelationList = new List<AccountContactRelation>([
            SELECT Id, accountid, contactid from AccountContactRelation where accountId in :accountIds]);
        Set<ID> contactIds = new set<Id>();
        for (AccountContactRelation acr : accountContactRelationList) {
            contactIds.add(acr.ContactId);
        }
        Map<Id, User> userMap = new Map<Id, user>([select id, contactid from User where contactid IN :contactIds]);

        // Query existing Account Shares
        List<AccountShare> existingAccountShares = new List<AccountShare>(
            [SELECT Id, AccountId, Account.ParentId, UserOrGroupId from AccountShare 
            where (UserOrGroupId in :userMap.keySet() or AccountId in :accountIds) and RowCause = 'Manual']);
        
        Set<Id> missingUserIds = new Set<Id>();
         for(AccountShare a : existingAccountShares) { 
             if (!userMap.containsKey(a.UserorGroupId)) {
                 missingUserIds.add(a.UserOrGroupId);
             }
         }

        // Query Again
        userMap = new Map<Id, user>([select id, contactid from User where contactid IN :contactIds or contactid in :missingUserIds]);

        Map<Id, Id> contactToUserMap = new Map<Id, Id>();
        for (User u : userMap.values()) {
            contactToUserMap.put(u.ContactId, u.Id);
        }
        
        List<AccountContactRelation> fullAccountContactRelationList = new List<AccountContactRelation>([
            SELECT Id, accountid, contactid from AccountContactRelation where contactId in :contactIds or contactid in :missingUserIds]);

        Map<ID,Set<ID>> accountToUserMap = new Map<ID,Set<ID>>();
        for(AccountContactRelation acr: fullAccountContactRelationList)
        { 
            if (contactToUserMap.containsKey(acr.ContactId)) {
                if (!accountToUserMap.containsKey(acr.accountId)) {
                    accountToUserMap.put(acr.accountId, new Set<Id>());
                }
                accountToUserMap.get(acr.accountId).add(contactToUserMap.get(acr.ContactId));
            }
        }

        // Process Account Shares and query again
        existingAccountShares = new List<AccountShare>(
            [SELECT Id, AccountId, Account.ParentId, UserOrGroupId, Account.Share_with_Parent__c from AccountShare 
            where UserOrGroupId in :userMap.keySet() and RowCause = 'Manual']);
         List<AccountShare> accountSharesToDelete = new List<AccountShare>(); 
         for(AccountShare a : existingAccountShares) { 
             if (userMap.containsKey(a.UserorGroupId)) {
                if (!a.Account.Share_With_Parent__c) {
                    accountSharesToDelete.add(a);
                } else if (a.Account.ParentId == null) {
                    accountSharesToDelete.add(a);
                } else if (!accountToUserMap.containsKey(a.Account.ParentId)) {
                    accountSharesToDelete.add(a);
                } else if (accountToUserMap.containsKey(a.Account.ParentId)) {
                    Set<Id> accountUserSet = accountToUserMap.get(a.Account.ParentId);
                    if (!accountUserSet.contains(a.UserorGroupId)) {
                        accountSharesToDelete.add(a);
                    }
                }
             }
         } 
         if (!accountSharesToDelete.isEmpty())
            Database.delete(accountSharesToDelete, false);

         // Process cases
         
        List<CaseShare> existingCaseShares = new List<CaseShare>(
            [SELECT Id, CaseId, Case.Account.ParentId, UserOrGroupId,
            Case.Account.Share_with_Parent__c from CaseShare 
            where UserOrGroupId in :userMap.keySet() and RowCause = 'Manual']
        );
         List<CaseShare> caseSharesToDelete = new List<CaseShare>(); 
         for(CaseShare c : existingCaseShares) { 
             if (userMap.containsKey(c.UserorGroupId)) {

                if (!c.Case.Account.Share_with_Parent__c) {
                    caseSharesToDelete.add(c);
                } else if (c.Case.Account.ParentId == null) {
                    caseSharesToDelete.add(c);
                } else if (!accountToUserMap.containsKey(c.Case.Account.ParentId)) {
                    caseSharesToDelete.add(c);
                } else if (accountToUserMap.containsKey(c.Case.Account.ParentId)) {
                    Set<Id> caseUserSet = accountToUserMap.get(c.Case.Account.ParentId);
                    if (!caseUserSet.contains(c.UserorGroupId)) {
                        caseSharesToDelete.add(c);
                    }
                }
             }
         } 
         if (!caseSharesToDelete.isEmpty())
            Database.delete(caseSharesToDelete, false);

        // Process Assets
         
        List<AssetShare> existingAssetShares = new List<AssetShare>(
            [SELECT Id, AssetId, Asset.Account.ParentId, UserOrGroupId,
            Asset.Account.Share_with_Parent__c from AssetShare 
            where UserOrGroupId in :userMap.keySet() and RowCause = 'Manual']
        );
         List<AssetShare> assetSharesToDelete = new List<AssetShare>(); 
         for(AssetShare c : existingAssetShares) { 
             if (userMap.containsKey(c.UserorGroupId)) {

                if (!c.Asset.Account.Share_with_Parent__c) {
                    assetSharesToDelete.add(c);
                } else if (c.Asset.Account.ParentId == null) {
                    assetSharesToDelete.add(c);
                } else if (!accountToUserMap.containsKey(c.Asset.Account.ParentId)) {
                    assetSharesToDelete.add(c);
                } else if (accountToUserMap.containsKey(c.Asset.Account.ParentId)) {
                    Set<Id> AssetUserSet = accountToUserMap.get(c.Asset.Account.ParentId);
                    if (!AssetUserSet.contains(c.UserorGroupId)) {
                        assetSharesToDelete.add(c);
                    }
                }
             }
         } 
         if (!assetSharesToDelete.isEmpty())
            Database.delete(assetSharesToDelete, false);
            
            // Process ServiceAppointments
            
            List<ServiceAppointmentShare> existingServiceAppointmentShares = new List<ServiceAppointmentShare>(
                [SELECT Id, ParentId, Parent.Account.ParentId, UserOrGroupId,
                Parent.Account.Share_with_Parent__c from ServiceAppointmentShare 
                where UserOrGroupId in :userMap.keySet() and RowCause = 'Manual']
            );
            List<ServiceAppointmentShare> serviceAppointmentSharesToDelete = new List<ServiceAppointmentShare>(); 
            for(ServiceAppointmentShare c : existingServiceAppointmentShares) { 
                if (userMap.containsKey(c.UserorGroupId)) {

                    if (!c.Parent.Account.Share_with_Parent__c) {
                        serviceAppointmentSharesToDelete.add(c);
                    } else if (c.Parent.Account.ParentId == null) {
                        serviceAppointmentSharesToDelete.add(c);
                    } else if (!accountToUserMap.containsKey(c.Parent.Account.ParentId)) {
                        serviceAppointmentSharesToDelete.add(c);
                    } else if (accountToUserMap.containsKey(c.Parent.Account.ParentId)) {
                        Set<Id> ServiceAppointmentUserSet = accountToUserMap.get(c.Parent.Account.ParentId);
                        if (!ServiceAppointmentUserSet.contains(c.UserorGroupId)) {
                            serviceAppointmentSharesToDelete.add(c);
                        }
                    }
                }
            } 
            if (!serviceAppointmentSharesToDelete.isEmpty())
                Database.delete(serviceAppointmentSharesToDelete, false);
        

        
            // Process Orders
            
            List<Order__Share> existingOrderShares = new List<Order__Share>(
                [SELECT Id, ParentId, 
                Parent.Bill_To_Account__c, 
                Parent.Ship_To_Account__c,
                Parent.Bill_To_Account__r.ParentId, 
                Parent.Ship_To_Account__r.ParentId, UserOrGroupId,
                Parent.Bill_To_Account__r.Share_with_Parent__c,
                Parent.Ship_To_Account__r.Share_with_Parent__c from Order__Share 
                where UserOrGroupId in :userMap.keySet() and RowCause = 'Manual']
            );
            List<Order__Share> orderSharesToDelete = new List<Order__Share>(); 
            for(Order__Share c : existingOrderShares) { 
                if (userMap.containsKey(c.UserorGroupId)) {

                    if (((c.Parent.Bill_To_Account__c != null && !c.Parent.Bill_To_Account__r.Share_with_Parent__c) &&
                            ((c.Parent.Ship_To_Account__c != null && !c.Parent.Ship_To_Account__r.Share_with_Parent__c) ||
                        c.Parent.Ship_To_Account__c == null)) ||
                        ((c.Parent.Ship_To_Account__c != null && !c.Parent.Ship_To_Account__r.Share_with_Parent__c) &&
                            ((c.Parent.Bill_To_Account__c != null && !c.Parent.Bill_To_Account__r.Share_with_Parent__c) ||
                        c.Parent.Bill_To_Account__c == null))) {
                        orderSharesToDelete.add(c);
                    } else if (c.Parent.Bill_To_Account__r.ParentId == null && c.Parent.Ship_To_Account__r.ParentId == null) {
                        orderSharesToDelete.add(c);
                    } else if (!accountToUserMap.containsKey(c.Parent.Bill_To_Account__r.ParentId) &&
                    !accountToUserMap.containsKey(c.Parent.Ship_To_Account__r.ParentId)) {
                        orderSharesToDelete.add(c);
                    } else if (accountToUserMap.containsKey(c.Parent.Bill_To_Account__r.ParentId)) {
                        Set<Id> billingOrderUserSet = accountToUserMap.get(c.Parent.Bill_To_Account__r.ParentId);
                        if (!billingOrderUserSet.contains(c.UserorGroupId)) {
                            if (accountToUserMap.containsKey(c.Parent.Ship_To_Account__r.ParentId)) {
                                Set<Id> shippingOrderUserSet = accountToUserMap.get(c.Parent.Ship_To_Account__r.ParentId);
                                 if (!shippingOrderUserSet.contains(c.UserorGroupId)) {
                                    orderSharesToDelete.add(c);
                                 }
                            } else {
                                orderSharesToDelete.add(c);
                            }
                        }
                    } else if (accountToUserMap.containsKey(c.Parent.Ship_To_Account__r.ParentId)) {
                        Set<Id> shippingOrderUserSet = accountToUserMap.get(c.Parent.Ship_To_Account__r.ParentId);
                        if (!shippingOrderUserSet.contains(c.UserorGroupId)) {
                            if (accountToUserMap.containsKey(c.Parent.Bill_To_Account__r.ParentId)) {
                                Set<Id> billingOrderUserSet = accountToUserMap.get(c.Parent.Bill_To_Account__r.ParentId);
                                 if (!billingOrderUserSet.contains(c.UserorGroupId)) {
                                    orderSharesToDelete.add(c);
                                 }
                            } else {
                                orderSharesToDelete.add(c);
                            }
                        }
                    }
                }
            } 
            if (!orderSharesToDelete.isEmpty())
                Database.delete(orderSharesToDelete, false);
        Database.update(scope, false);
    }
    
    public void finish(Database.BatchableContext bc){
    }
}