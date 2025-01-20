@isTEst
public class CL_TermsOfUseTest {

    public static testMethod void testOtherUser() {
        User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
        ID ProfileID = [ Select id,UserType from Profile where name = 'Self-Service Portal User'].id;
        
        Account A2 = new Account(Name = 'Child Account', Site_Use_ID_SFDC__c = 'test2', Site_Usage__c	 = 'INSTALL_AT', Share_with_Parent__c = true );
        insert A2;
        
        Contact C1 = new Contact( AccountID = A2.id, FirstName = 'Test', LastName = 'User', 
        email = 'test-user@fakeemail.com' );
        insert C1; 
        
        User u1 = new User( email='test-user@fakeemail.com', contactid = c1.id, profileid = profileID, 
                  UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1', 
                  TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', 
                  LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User');
        insert u1;
        System.runAs(u1) {
        
            CommunitiesLandingController ctrl1 = new CommunitiesLandingController();
            ctrl1.forwardToStartPage();
            termsOfUseController ctrl2 = new termsOfUseController();
            ctrl2.cancel();
            ctrl2.checkACcepted();
            try {
            ctrl2.accept();
            } catch (Exception e) {

            }
            CL_CheckTermsOfUseController.checkAccepted();
        }
    }
}