public class CL_UserTriggerHandler {
    public static void afterInsert(List<User> newUsers) {
        List<User> usersToProcess = new List<User>();
        for (User c : newUsers) {
            if (c.ContactId != null) {
                usersToProcess.add(c);
            }
        }
        if (!usersToProcess.isEmpty()) {
            updateAccountShareFlag(usersToProcess);
        }
    }
    public static void afterUpdate(List<User> updatedUsers, Map<Id, User> oldUserMap) {
        List<User> usersToProcessCreate = new List<User>();
        for (User c : updatedUsers) {
            if (oldUserMap.get(c.Id).IsActive != c.IsActive && c.IsActive) {
                if (c.ContactId != null) {
                    usersToProcessCreate.add(c);
                }
            }
        }
        if (!usersToProcessCreate.isEmpty()) {
            updateAccountShareFlag(usersToProcessCreate);
        }
    }

    public static void updateAccountShareFlag(List<User> newUsers) {
    
        Set<Id> contactIds = new Set<Id>();
        for (User c : newUsers) {
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
}