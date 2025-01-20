public class CL_CaseCommentController {

    @AuraEnabled(cacheable=false)
    public static boolean checkEditAccess() {
        List<User> userList = new List<User>([SELECT Id,Profile.Name from User where Id = :UserInfo.getUserId()]);
        SYstem.debug('### reached here');
        if (!userList.isEmpty()) {
            User u = userList.get(0);
            if (u.Profile.Name.equals('System Administrator')) {
        SYstem.debug('### reached here2');

                return true;
            } else {
                List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>([SELECT Id, PermissionSetId, PermissionSet.Name, 
                PermissionSet.ProfileId, PermissionSet.Profile.Name, 
                AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE AssigneeId = :u.Id and PermissionSet.Name = 'Edit_Case_Comments']);
                if (!assignments.isEmpty()) {
        SYstem.debug('### reached here3');
                    return true;
                }
            }
        }

        SYstem.debug('### reached here4');
        return false;
    }
    @AuraEnabled(cacheable=false)
    public static boolean checkNoDeleteAccess() {
        List<User> userList = new List<User>([SELECT Id, Profile.Name from User where Id = :UserInfo.getUserId()]);
        if (!userList.isEmpty()) {
            User u = userList.get(0);
            if (u.Profile.Name.equals('Self-Service Portal User')) {
                return true;
            } else if (u.Profile.Name.equals('System Administrator')) {
                return false;
            } else {
                List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>([SELECT Id, PermissionSetId, PermissionSet.Name, 
                PermissionSet.ProfileId, PermissionSet.Profile.Name, 
                AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE AssigneeId = :u.Id and PermissionSet.Name = 'Edit_Case_Comments']);
                if (!assignments.isEmpty()) {
                    return false;
                }
            }
        }
        return true;
    }
    @AuraEnabled(cacheable=false)
    public static boolean checkNoNewAccess(String caseId) {
        List<Case> caseList = new List<Case>([SELECT Id, Status from Case where Id = :caseId]);
        if (!caseList.isEmpty()) {
            Case c = caseList.get(0);
            if (c.Status.equals('Closed') || c.Status.equals('Completed in Salesforce') || c.Status.equals('Completed')) {
                List<User> userList = new List<User>([SELECT Id, Profile.Name from User where Id = :UserInfo.getUserId()]);
                if (!userList.isEmpty()) {
                    for (User u : userList) {
                        if (u.Profile.Name.equals('Self-Service Portal User')) {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }
    @AuraEnabled(cacheable=false)
    public static List<CaseComment> getCaseComments(String caseId) {
        List<CaseComment> comments = new List<CaseComment>([
            SELECT Id, parentid, createddate, ispublished,  createdby.name, createdbyid, commentbody from casecomment where parentid = :caseId
            order by createddate desc]);
        return comments;
    }
    
    @AuraEnabled(cacheable=false)
    public static boolean getCase(String caseId) {
        
            List<Case> caseList = new List<Case>([SELECT id from case where id = :caseId]);
          if (!caseList.isEmpty()) return true;
        return false;
    }

    @AuraEnabled
    public static List<CaseComment> deleteCaseComments(List<String> conObj, Id caseId){
        List<CaseComment> conObjItem = NEW   List<CaseComment>();
      List<CaseComment> conObjList = new List<CaseComment>([SELECT Id  FROM CaseComment WHERE Id IN:conObj]);
      System.debug('### conObj ' +conObj);
      System.debug('### conObjList ' +conObjList);
     
      IF(conObjList.size()>0){
          try{
            DELETE conObjList;           
          }
          catch (Exception EXP) {
            throw NEW AuraHandledException(EXP.getMessage());
        }
      }
      RETURN conObjList;
    }
}