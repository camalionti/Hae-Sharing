public class CL_AssetTriggerHandler {
    public static void afterInsert(List<Asset> newAssets) {
        List<Asset> assetsToProcess = new List<Asset>();
        for (Asset c : newAssets) {
            if (c.AccountId != null) {
                assetsToProcess.add(c);
            }
        }
        if (!AssetsToProcess.isEmpty()) {
            updateAccountShareFlag(assetsToProcess);
        }
    }
    public static void afterUpdate(List<Asset> updatedAssets, Map<Id, Asset> oldAssetMap) {
        List<Asset> assetsToProcessCreate = new List<Asset>();
        List<Asset> assetsToProcessDelete = new List<Asset>();
        Set<Id> assetIdSetToDeleteShares = new Set<Id>();
        for (Asset c : updatedAssets) {
            if (oldAssetMap.get(c.Id).AccountId != c.AccountId) {
                if (c.AccountId != null) {
                    assetsToProcessCreate.add(c);
                }
                if (oldAssetMap.get(c.Id).AccountId != null) {
                    assetsToProcessDelete.add(oldAssetMap.get(c.Id));
                }
                if (!c.Has_Parent_Account__c) {
                    assetIdSetToDeleteShares.add(c.Id);
                }
            }
        }
        if (!assetsToProcessCreate.isEmpty()) {
            updateAccountShareFlag(assetsToProcessCreate);
        }
        if (!assetsToProcessDelete.isEmpty()) {
            updateAccountDeleteFlag(assetsToProcessDelete);
        }
        if (!assetIdSetToDeleteShares.isEmpty()) {
            deleteShares(assetIdSetToDeleteShares);
        }
    }

    public static void updateAccountShareFlag(List<Asset> newAssets) {
    
        Set<Id> parentIds = new Set<Id>();
        for (Asset c : newAssets) {
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

    
    
    public static void updateAccountDeleteFlag(List<Asset> oldAssets) {
    	
        Set<Id> accountIds = new Set<Id>();
        for (Asset c : oldAssets) {
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

    public static void deleteShares(Set<Id> assetIdSet) {
        List<AssetShare> assetShareList = new List<AssetShare>([SELECT Id from AssetShare  
        where assetId in :assetIdSet and RowCause = 'Manual']);
         if (!assetShareList.isEmpty())
         	Database.delete(assetShareList, false);
    }
}