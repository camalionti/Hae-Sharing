public class CL_OrderTriggerHandler {
    public static void afterInsert(List<Order__c> newOrders) {
        List<Order__c> ordersToProcess = new List<Order__c>();
        for (Order__c c : newOrders) {
            if (c.Bill_To_Account__c != null ||
            c.Ship_To_Account__c != null) {
                ordersToProcess.add(c);
            }
        }
        if (!ordersToProcess.isEmpty()) {
            updateAccountShareFlag(ordersToProcess);
        }
    }
    public static void afterUpdate(List<Order__c> updatedOrders, Map<Id, Order__c> oldOrderMap) {
        List<Order__c> ordersToProcessCreate = new List<Order__c>();
        List<Order__c> ordersToProcessDelete = new List<Order__c>();
        Set<Id> orderIdSetToDeleteShares = new Set<Id>();
        for (Order__c c : updatedOrders) {
            if (oldOrderMap.get(c.Id).Bill_To_Account__c != c.Bill_To_Account__c ||
            oldOrderMap.get(c.Id).Ship_To_Account__c != c.Ship_To_Account__c ) {
                if (c.Bill_To_Account__c != null ||
                    c.Ship_To_Account__c != null) {
                    ordersToProcessCreate.add(c);
                }
                if ((oldOrderMap.get(c.Id).Bill_To_Account__c != null && oldOrderMap.get(c.Id).Bill_To_Account__c != c.Bill_To_Account__c) ||
                (oldOrderMap.get(c.Id).Ship_To_Account__c != null && oldOrderMap.get(c.Id).Ship_To_Account__c != c.Ship_To_Account__c) ) {
                    ordersToProcessDelete.add(oldOrderMap.get(c.Id));
                }
                if (!c.Has_Bill_To_Parent__c && !c.Has_Ship_To_Parent__c) {
                    orderIdSetToDeleteShares.add(c.Id);
                }
            }
        }
        if (!ordersToProcessCreate.isEmpty()) {
            updateAccountShareFlag(ordersToProcessCreate);
        }
    }

    public static void updateAccountShareFlag(List<Order__c> newOrders) {
    
        Set<Id> parentIds = new Set<Id>();
        for (Order__c c : newOrders) {
            if (c.Bill_To_Account__c != null)
                parentIds.add(c.Bill_To_Account__c);
            if (c.Ship_To_Account__c != null)
                parentIds.add(c.Ship_To_Account__c);
        }

        List<Account> accountList = new List<Account>([SELECT Id, parentid, Update_Shares__c from account 
        where Share_With_Parent__c = true and parentId in :parentIds and Update_Shares__c = false]);
        for (Account a : accountList) {
            a.Update_Shares__c = true;
        }
         if (!accountList.isEmpty())
         	Database.update(accountList, false);
    }
    
    
    public static void updateAccountDeleteFlag(List<Order__c> oldOrders) {
    	
        Set<Id> accountIds = new Set<Id>();
        for (Order__c c : oldOrders) {
            if (c.Bill_To_Account__c != null)
                accountIds.add(c.Bill_To_Account__c);
            if (c.Ship_To_Account__c != null)
                accountIds.add(c.Ship_To_Account__c);
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

    public static void deleteShares(Set<Id> orderIdSet) {
        List<Order__Share> orderShareList = new List<Order__Share>([SELECT Id from Order__Share  
        where ParentId in :orderIdSet and RowCause = 'Manual']);
         if (!orderShareList.isEmpty())
         	Database.delete(orderShareList, false);
    }
}