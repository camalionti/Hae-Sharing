public class CL_CaseTriggerHandler {
    public static void afterInsert(List<Case> newCases) {
        List<Case> casesToProcess = new List<Case>();
        for (Case c : newCases) {
            if (c.AccountId != null) {
                casesToProcess.add(c);
            }
        }
        if (!casesToProcess.isEmpty()) {
            updateAccountShareFlag(casesToProcess);
        }
    }
    public static void afterUpdate(List<Case> updatedCases, Map<Id, Case> oldCaseMap) {
        List<Case> casesToProcessCreate = new List<Case>();
        List<Case> casesToProcessDelete = new List<Case>();
        Set<Id> caseIdSetToDeleteShares = new Set<Id>();
        for (Case c : updatedCases) {
            if (oldCaseMap.get(c.Id).AccountId != c.AccountId) {
                if (c.AccountId != null) {
                    casesToProcessCreate.add(c);
                }
                if (oldCaseMap.get(c.Id).AccountId != null) {
                    casesToProcessDelete.add(oldCaseMap.get(c.Id));
                }
                if (!c.Has_Parent_Account__c) {
                    caseIdSetToDeleteShares.add(c.Id);
                }
            }
        }
        if (!casesToProcessCreate.isEmpty()) {
            updateAccountShareFlag(casesToProcessCreate);
        }
        if (!casesToProcessDelete.isEmpty()) {
            updateAccountDeleteFlag(casesToProcessDelete);
        }
        if (!caseIdSetToDeleteShares.isEmpty()) {
            deleteShares(caseIdSetToDeleteShares);
        }
    }

    public static void updateAccountShareFlag(List<Case> newCases) {
    
        Set<Id> parentIds = new Set<Id>();
        for (Case c : newCases) {
            if (c.AccountId != null)
                parentIds.add(c.accountId);
        }

        List<Account> accountList = new List<Account>([SELECT Id, parentid, Update_Shares__c from account 
        where Share_With_Parent__c = true and parentId in :parentIds and Update_Shares__c = false]);
        for (Account a : accountList) {            
            a.Update_Shares__c = true;
        }
         if (!accountList.isEmpty())
         	Database.update(accountList, false);
    }

    
    public static void updateAccountDeleteFlag(List<Case> oldCases) {
    	
        Set<Id> accountIds = new Set<Id>();
        for (Case c : oldCases) {
            if (c.AccountId != null)
                accountIds.add(c.accountId);
        }

        List<Account> accountList = new List<Account>([SELECT Id, parentid, Delete_Shares__c from account 
        where Id in :accountIds and Delete_Shares__c = false and ParentId != null]);
        Map<Id, Account> accountsToUpdateMap = new Map<Id, Account>();
        for (Account a : accountList){ 
            Account p = new Account(Id = a.ParentId, Delete_Shares__c = true);
            accountsToUpdateMap.put(p.Id, p);
        }
         if (!accountsToUpdateMap.isEmpty())
         	Database.update(accountsToUpdateMap.values(), false);
    }

    public static void deleteShares(Set<Id> caseIdSet) {
        List<CaseShare> caseShareList = new List<CaseShare>([SELECT Id from CaseShare 
        where CaseId in :caseIdSet and RowCause = 'Manual']);
         if (!caseShareList.isEmpty())
         	Database.delete(caseShareList, false);
    }
}