public class CL_ServiceAppointmentTriggerHandler {
    public static void afterInsert(List<ServiceAppointment> newServiceAppointments) {
        List<ServiceAppointment> serviceAppointmentsToProcess = new List<ServiceAppointment>();
        for (ServiceAppointment c : newServiceAppointments) {
            if (c.AccountId != null) {
                serviceAppointmentsToProcess.add(c);
            }
        }
        if (!serviceAppointmentsToProcess.isEmpty()) {
            updateAccountShareFlag(serviceAppointmentsToProcess);
        }
    }
    public static void afterUpdate(List<ServiceAppointment> updatedServiceAppointments, Map<Id, ServiceAppointment> oldServiceAppointmentMap) {
        List<ServiceAppointment> serviceAppointmentsToProcessCreate = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsToProcessDelete = new List<ServiceAppointment>();
        Set<Id> serviceAppointmentIdSetToDeleteShares = new Set<Id>();
        for (ServiceAppointment c : updatedServiceAppointments) {
            if (oldServiceAppointmentMap.get(c.Id).AccountId != c.AccountId) {
                if (c.AccountId != null) {
                    serviceAppointmentsToProcessCreate.add(c);
                }
                if (oldServiceAppointmentMap.get(c.Id).AccountId != null) {
                    serviceAppointmentsToProcessDelete.add(oldServiceAppointmentMap.get(c.Id));
                }
                if (!c.Has_Parent_Account__c) {
                    serviceAppointmentIdSetToDeleteShares.add(c.Id);
                }
            }
        }
        if (!serviceAppointmentsToProcessCreate.isEmpty()) {
            updateAccountShareFlag(serviceAppointmentsToProcessCreate);
        }
        if (!serviceAppointmentsToProcessDelete.isEmpty()) {
            updateAccountDeleteFlag(serviceAppointmentsToProcessDelete);
        }
        if (!serviceAppointmentIdSetToDeleteShares.isEmpty()) {
            deleteShares(serviceAppointmentIdSetToDeleteShares);
        }
    }

    public static void updateAccountShareFlag(List<ServiceAppointment> newServiceAppointments) {
    
        Set<Id> parentIds = new Set<Id>();
        for (ServiceAppointment c : newServiceAppointments) {
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

    
    public static void updateAccountDeleteFlag(List<ServiceAppointment> oldserviceAppointments) {
    	
        Set<Id> accountIds = new Set<Id>();
        for (ServiceAppointment c : oldserviceAppointments) {
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

    public static void deleteShares(Set<Id> serviceAppointmentIdSet) {
        List<ServiceAppointmentShare> serviceAppointmentShareList = new List<serviceAppointmentShare>([SELECT Id from ServiceAppointmentShare 
        where ParentId in :serviceAppointmentIdSet and RowCause = 'Manual']);
         if (!serviceAppointmentShareList.isEmpty())
         	Database.delete(serviceAppointmentShareList, false);
    }
}