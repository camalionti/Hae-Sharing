public class CL_CaseCommentTriggerHandler {
    public static void beforeInsert(List<CaseComment> newComments) {
        
        List<Profile> profileList = new List<Profile>([select Name from profile where id = :UserInfo.getProfileId()]);
        if (!profileList.isEmpty()) {
            String profileName = profileList.get(0).Name;
            if (profileName.equals('Self-Service Portal User')) {
                Set<Id> caseIdSet = new set<Id>();
                for (CaseComment cc : newComments) {
                    caseIdSet.add(cc.ParentId);
                }
                Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id from CAse where Status = 'Closed' and Id in :caseIdSet]);
                
                for (CaseComment cc : newComments) {
                    if (caseMap.containsKey(cc.ParentId))
                        cc.addError('You cannot add a case comment to a closed Case!');
                }
            }
        }
    }
}