@isTest
private class DisplayEmailTemplateControllerTest {
 
  @isTest
    private static void testGetTempList() {
      System.assert( DisplayEmailTemplateController.getTempList()!=null, 'getTempList returned NULL instead of List');
    }


}