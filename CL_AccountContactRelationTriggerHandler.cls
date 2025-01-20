public class CL_AccountContactRelationTriggerHandler {

    public static void afterInsert(List<AccountContactRelation> newRelations) {
        List<AccountContactRelation> relationsToProcess = new List<AccountContactRelation>();
        for (AccountContactRelation acr : newRelations) {
            if (acr.ContactId != null) {
                relationsToProcess.add(acr);
            }
        }
        if (!relationsToProcess.isEmpty()) {
            updateAccountShareFlag(relationsToProcess);
        }
    }
    public static void afterDelete(List<AccountContactRelation> deletedRelations) {
        if (!deletedRelations.isEmpty()) {
            updateAccountDeleteFlag(deletedRelations);
        }
    }

    public static void updateAccountShareFlag(List<AccountContactRelation> newRelations) {
    
        Set<Id> contactIds = new Set<Id>();
        for (AccountContactRelation c : newRelations) {
            contactIds.add(c.ContactId);
        }
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, accountid from contact where Id in :contactIds]);
        
        Set<Id> parentIds = new Set<Id>(); 
        for (Contact c : contactMap.values()) {
            parentIds.add(c.AccountId);
        }

        List<Account> accountList = new List<Account>([SELECT Id, parentid, Update_Shares__c from account 
        where Share_With_Parent__c = true and parentId in :parentIds and Update_Shares__c = false]);
        for (Account a : accountList) {
            a.Update_Shares__c = true;
        }
         if (!accountList.isEmpty())
         	Database.update(accountList, false);
    }
    
    
    public static void updateAccountDeleteFlag(List<AccountContactRelation> deletedRelations) {
    	Map<Id,Account> accountMap = new Map<Id,Account>();
        for (AccountContactRelation acr : deletedRelations) {
            Account a = new Account(Id = acr.AccountId, Delete_Shares__c = true);
            accountMap.put(a.Id, a);
        }
         if (!accountMap.isEmpty())
         	Database.update(accountMap.values(), false);
    }
}