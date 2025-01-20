public class CL_AccountTriggerHandler {
    private static boolean recursionFlag = false;
    public static void beforeInsert(List<Account> newAccounts) {
        List<Account> accountsToProcess = new List<Account>();
        for (Account a : newAccounts) {
            if (a.ParentId != null && a.Share_With_Parent__c) {
                a.Update_Shares__c = true;
            }
        }
    }
    public static void afterInsert(List<Account> newAccounts) {
        if (!recursionFlag) {
            for (Account a : newAccounts) {
                if (a.Update_Shares__c || a.Delete_Shares__c) {
                    Database.executeBatch(new CL_UpdateShareBatch(), 10);
                    recursionFlag = true;
                    break;
                }
            }
        }
    }
    public static void beforeUpdate(List<Account> updatedAccounts, Map<Id, Account> oldAccountMap) {
        List<Account> accountsToUpdate = new List<Account>();
        for (Account a : updatedAccounts) {
            if ((oldAccountMap.get(a.Id).ParentId != a.ParentId && a.Share_With_Parent__c && a.ParentId != null) ||
            (oldAccountMap.get(a.Id).Share_With_Parent__c != a.Share_With_Parent__c && a.ParentId != null && a.Share_With_Parent__c)) {
              a.Update_Shares__c = true;
            }
        }
    }
    public static void afterUpdate(List<Account> updatedAccounts, Map<Id, Account> oldAccountMap) {
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        for (Account a : updatedAccounts) {
            if ((oldAccountMap.get(a.Id).ParentId != a.ParentId && a.Share_With_Parent__c &&
            oldAccountMap.get(a.Id).ParentId != null && oldAccountMap.get(a.Id).Share_With_Parent__c) || (
                oldAccountMap.get(a.Id).Share_With_Parent__c != a.Share_With_Parent__c 
                && oldAccountMap.get(a.Id).ParentId != null && oldAccountMap.get(a.Id).Share_With_Parent__c
            ) ) {
                    Account p = new Account(Id = oldAccountMap.get(a.Id).ParentId, Delete_Shares__c = true);
                    accountsToUpdate.put(p.Id, p);
                }
        }
        if (!accountsToUpdate.isEmpty()) {
        	Database.update(accountsToUpdate.values(), false);
        } else if (!recursionFlag) {
            for (Account a : updatedAccounts) {
                if (a.Update_Shares__c || a.Delete_Shares__c) {

                    Database.executeBatch(new CL_UpdateShareBatch(), 10);
                    recursionFlag = true;
                    break;
                }
            }
        }
    }
    /*public static void afterInsert(List<Account> newAccounts) {
        List<Account> accountsToProcess = new List<Account>();
        for (Account c : newAccounts) {
            if (c.ParentId != null && c.Share_With_Parent__c) {
                accountsToProcess.add(c);
            }
        }
        if (!accountsToProcess.isEmpty()) {
            processCreateShares(accountsToProcess);
        }
    }
    public static void afterUpdate(List<Account> updatedAccounts, Map<Id, Account> oldAccountMap) {
        List<Account> accountsToProcessCreate = new List<Account>();
        Map<Id, Account> accountsToProcessDeleteMap = new Map<Id, Account>();
        for (Account c : updatedAccounts) {
            if (oldAccountMap.get(c.Id).ParentId != c.ParentId && c.Share_With_Parent__c) {
                if (c.ParentId != null) {
                    accountsToProcessCreate.add(c);
                }
                if (oldAccountMap.get(c.Id).ParentId != null && oldAccountMap.get(c.Id).Share_With_Parent__c) {
                    accountsToProcessDeleteMap.put(c.Id, oldAccountMap.get(c.Id));
                }
            } else if (oldAccountMap.get(c.Id).Share_With_Parent__c != c.Share_With_Parent__c) {
                if (c.ParentId != null && c.Share_With_Parent__c) {
                    accountsToProcessCreate.add(c);
                }
                if (oldAccountMap.get(c.Id).ParentId != null && !oldAccountMap.get(c.Id).Share_With_Parent__c) {
                    accountsToProcessDeleteMap.put(c.Id, oldAccountMap.get(c.Id));
                }
            }
        }
        if (!accountsToProcessCreate.isEmpty()) {
            processCreateShares(accountsToProcessCreate);
        }
        if (!accountsToProcessDeleteMap.isEmpty()) {
            processDeleteShares(accountsToProcessDeleteMap);
        }
    }

    public static void processCreateShares(List<Account> newAccounts) {
        Set<Id> parentIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<ID,ID> accountToParentMAp = new Map<ID,ID>();
        for (Account a : newAccounts) {
            parentIds.add(a.ParentId);
            accountIds.add(a.Id);
            accountToParentMap.put(a.Id, a.PArentId);
        }
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, accountid from contact where accountId in :parentIds]);
        
        Set<ID> contactIds = contactMap.keySet(); 
        List<User> userList = new List<user>([select id, contactid, contact.accountId from User where contactid IN :contactIds]);
        Map<ID,Set<ID>> accountToUserMap = new Map<ID,Set<ID>>();
        for(User u: userList)
        { 
            if (!accountToUserMap.containsKey(u.contact.accountId)) {
                accountToUserMap.put(u.contact.accountId, new Set<Id>());
            }
            accountToUserMap.get(u.contact.accountId).add(u.Id);
        }
         List<AccountShare> accountSharesToCreate = new List<AccountShare>(); 
         for(Account a : newAccounts) { 
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
         for(Account a : newAccounts) { 
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
            Database.insert(caseSharesToCreate, true);

    }
        
    public static void processDeleteShares(Map<Id, Account> oldAccountMap) {
    
        Set<Id> parentIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> oldAccountIds = oldAccountMap.keySet();
        Map<ID,ID> accountToParentMAp = new Map<ID,ID>();
        for (Account a : oldAccountMap.values()) {
            parentIds.add(a.ParentId);
            accountIds.add(a.Id);
            accountToParentMap.put(a.Id, a.PArentId);
        }
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, accountid from contact where accountId in :parentIds]);
        
        Set<ID> contactIds = contactMap.keySet(); 
        Map<Id, User> userMap = new Map<Id, user>([select id, contactid, contact.accountId from User where contactid IN :contactIds]);
        Set<ID> userIds = userMap.keySet();
        Map<ID,Set<ID>> accountToUserMap = new Map<ID,Set<ID>>();
        for(User u: userMap.values())
        { 
            if (!accountToUserMap.containsKey(u.contact.accountId)) {
                accountToUserMap.put(u.contact.accountId, new Set<Id>());
            }
            accountToUserMap.get(u.contact.accountId).add(u.Id);
        }
         List<AccountShare> accountShareList = new List<AccountShare>([
             SELECT Id, AccountId, UserOrGroupId, RowCause from AccountShare
         where RowCause = 'Manual' and UserOrGroupId in :userIds and AccountId in :accountIds]); 
         List<AccountShare> accountShareToDelete = new List<AccountShare>(); 
         for(AccountShare a : accountShareList) { 
             Account oldAccount = oldAccountMap.get(a.AccountId);
             if (accountToParentMap.containsKey(oldAccount.Id)) {
                 Id parentId = accountToParentMap.get(oldAccount.Id);
                 if (accountToUserMap.containsKey(parentId)) {
                     for (Id userId : accountToUserMap.get(parentId)) {
                        if (a.UserOrGroupId == userId) {
                            accountShareToDelete.add(a);
                            break;
                        }
                     }
                 }
             }
         } 
         if (!accountShareToDelete.isEmpty())
            Database.delete(accountShareToDelete, false);

        // Process cases
        
         List<CaseShare> caseShareList = new List<CaseShare>([
             SELECT Id, CaseId, Case.AccountId, UserOrGroupId, RowCause from CaseShare
         where RowCause = 'Manual' and UserOrGroupId in :userIds and Case.AccountId in :accountIds]); 
         List<CaseShare> caseShareToDelete = new List<CaseShare>(); 
         for(CaseShare c : caseShareList) { 
             Account oldAccount = oldAccountMap.get(c.Case.AccountId);
             if (accountToParentMap.containsKey(oldAccount.Id)) {
                 Id parentId = accountToParentMap.get(oldAccount.Id);
                 if (accountToUserMap.containsKey(parentId)) {
                     for (Id userId : accountToUserMap.get(parentId)) {
                        if (c.UserOrGroupId == userId) {
                            caseShareToDelete.add(c);
                            break;
                        }
                     }
                 }
             }
         } 
         if (!caseShareToDelete.isEmpty())
            Database.delete(caseShareToDelete, false);

    }*/
        
}