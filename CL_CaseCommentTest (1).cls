@isTEst
public class CL_CaseCommentTest {

    @testSetup static void setup() {
        
        List<HAE_Operating_Unit__c> operatingUnitList = new List<HAE_Operating_Unit__c>();
        List<HAE_User_Operating_Unit__c> userOperatingUnitList = new List<HAE_User_Operating_Unit__c>();
        List<Account> billToAccList = new List<Account>();
        List<Account> shipToAccList = new List<Account>();
        List<Account> primaryAccList = new List<Account>();
        List<HAE_Product_Category__c> productCategoryList = new List<HAE_Product_Category__c>();
        List<Product2> prodList = new List<Product2>();
        List<workOrder> workOrderList = new List<workOrder>();
        List<Asset> assetList = new List<Asset>();
        List<HAE_Code__c> codeList = new List<HAE_Code__c>();
        List<HAE_Code_Category_Assignment__c> problemCodeList = new List <HAE_Code_Category_Assignment__c>();
        List<assignedResource> assignedResourceList = new List<assignedResource>();
        List<serviceAppointment>serviceAppointmentList = new  List<serviceAppointment>();
        List<case> caseList = new List<case>();
        user fsmUser = new user();
        User productSupportUser = HAE_FS_TestDataFactory.getInternalUser('Product Support', 'ps');
        
          try{  
                FSL.GlobalAPIS.addStatusTransition('Hold Paid Service', 'Scheduled');
                FSL.GlobalAPIS.addStatusTransition('Hold Paid Service', 'completed');
                FSL.GlobalAPIS.addStatusTransition('Hold Paid Service', 'Canceled');
                FSL.GlobalAPIS.addStatusTransition( 'Scheduled','completed');
                FSL.GlobalAPIS.addStatusTransition( 'Scheduled','Canceled');
                HAE_FS_TestDataFactory.setCustomSettings();
                operatingUnitList = HAE_FS_TestDataFactory.getOperatingUnits(1, '102', 'Haemonetics Corp US OU', 'NA'); 
                userOperatingUnitList = HAE_FS_TestDataFactory.getUserOperatingUnits(1, operatingUnitList ,productSupportUser,false );     
                fsmUser = HAE_FS_TestDataFactory.getInternalUser('System Administrator','fsm');
                billToAccList = HAE_FS_TestDataFactory.getAccounts(1,'Transactional_Account', 'Bill To', operatingUnitList,false);
                billToAccList[0].Site_Usage__c = 'BILL_TO';
                update billToAccList;
                shipToAccList = HAE_FS_TestDataFactory.getAccounts(1,'Transactional_Account', 'Ship To', operatingUnitList,false);
                primaryAccList = HAE_FS_TestDataFactory.getAccounts(1,'Transactional_Account', 'Bill To', operatingUnitList,true);
                 productCategoryList = HAE_FS_TestDataFactory.getProductCategories(1);
                 productCategoryList[0].name ='PL.Equi.Mach.NexSys';
                 update productCategoryList;
                 prodList = HAE_FS_TestDataFactory.getProducts(1, productCategoryList[0], 'PCS 300', 'Oracle');
                 primaryAccList[0].Site_Usage__c = 'INSTALL_AT';
                 primaryAccList[0].Site_Use_ID_SFDC__c = '123';
                 update primaryAccList[0];
                 assetList = HAE_FS_TestDataFactory.getAssets(1, prodList, 'Non_Component', primaryAccList[0]);
                 Test.startTest();
                 codeList = HAE_FS_TestDataFactory.getcodes(1,'HAE_Problem_Code',true);
                 problemCodeList = HAE_FS_TestDataFactory.getCodeCategoryAssignments(productCategoryList,codeList);
                 List<Fsl_matrix__c>  fslm = HAE_FS_TestDataFactory.getFSLMatrix('FSE Preventive Maintenance','FSE Preventive Maintenance'); 
                 caseList = HAE_FS_TestDataFactory.getCases(1, 'HAE_FSE_Preventive_Maintenance',assetList[0],primaryAccList[0],billToAccList[0],shipToAccList[0],problemCodeList,operatingUnitList[0]);
                 workOrderList = [select id from workorder LIMIT 1];
                 serviceAppointmentList = HAE_FS_TestDataFactory.getappointments(1,workOrderList[0]);
                 List<contact> conList = HAE_FS_TestDataFactory.getContacts(1,primaryAccList);              
                Test.stopTest();
               }
            catch (Exception ex){
                System.debug('Exception :'+ex.getMessage()+ ex.getCause()+ex.getLineNumber());
            }  
            
    }
    
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
        Case c = [select id, status,ownerid from case limit 1];
        c.ownerid = u1.ID;
        c.status = 'Completed';
        update c;
        System.runAs(u1) {
        
        CL_CaseCommentController.checkEditAccess();
        CL_CaseCommentController.checkNoDeleteAccess();
        CL_CaseCommentController.checkNoNewAccess(c.Id);
        try {
        CaseComment comment = new CaseComment(commentbody = 'test', ParentId = c.Id);
        insert comment;
        } catch (Exception e) {

        }
        }
    }
    public static testMethod void test1() {
        Case c = [select id, status from case limit 1];
        CaseComment comment2 = new CaseComment(commentbody = 'test', ParentId = c.Id);
        insert comment2;
        c.status = 'Completed';
        update c;
        try {
        CaseComment comment = new CaseComment(commentbody = 'test', ParentId = c.Id);
        insert comment;
        } catch (Exception e) {

        }
        
        c.status = 'Open';
        update c;
        CL_CaseCommentController.checkEditAccess();
        CL_CaseCommentController.checkNoDeleteAccess();
        CL_CaseCommentController.checkNoNewAccess(c.Id);
        CL_CaseCommentController.getCaseComments(c.Id);
        CL_CaseCommentController.getCase(c.Id);
        CL_CaseCommentController.deleteCaseComments(new List<String>{comment2.Id}, c.Id);
    }
}