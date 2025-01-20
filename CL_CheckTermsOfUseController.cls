public class CL_CheckTermsOfUseController {
    
    @AuraEnabled(cacheable=false)
    public static Boolean checkAccepted() {
        List<User> userList = new List<User>([SELECT Id, ContactId from User where Id = :UserInfo.getUserId()]);
        Id contactId;
        if (!userList.isEmpty()) {
            for (User u : userList) {
                if (u.ContactId != null) {
                    contactId = u.ContactId;
                    //break;
                }
            }
        }
        boolean acceptedTermsOfUse = false;
        if (contactId != null) {
            List<Contact> contactList = new List<Contact>([SELECT Id, Accepted_Terms_of_Use__c from Contact where Id = :contactId]);
            if (!contactList.isEmpty()) {
                for (Contact c : contactList) {
                    return c.Accepted_Terms_of_Use__c;
                }
            }
        }
        return true;
    }
}