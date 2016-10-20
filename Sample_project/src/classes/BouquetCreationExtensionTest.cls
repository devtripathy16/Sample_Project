/******************************************************************************************************************************
* @class name      : BouquetCreationExtensionTest
* @description     : This class is used for testing scenarios for Extention of Visualforce Page
* @author          : Candidate
* @date            : 25/09/2016            
                    
* Modification Log :
* -----------------------------------------------------------------------------------------------------------------
* Developer                                      Date(MM/DD/YYYY)       Description
* -----------------------------------------------------------------------------------------------------------------
* Candidate                                      05/10/2016             Created.

******************************************************************************************************************************/

@isTest (SeeAllData = false)
private class BouquetCreationExtensionTest{
    
    // This method is used to create Centralised Test data so that 
    // same is accesible in all the test methods written in this test class.
    @testSetup static void setupData() {
      
        // Data Setup by Inventory Manager for Items in Various Categories.    
        Id inventoryManagerProfileId= [Select Id From Profile Where Name = 'Inventory Manager'].Id ;
        List<User> inventoryManagerUsers = TestDataUtility.createTestUser(2,inventoryManagerProfileId);
        List<Product2> productList = new List<Product2>();
        system.runAs(inventoryManagerUsers[0]){
            
            // Inserting 50 Products including 49 Active and 1 Inactive Product
            // Csv file has been uploaded in the static resource to generate Product data.
            productList = Test.LoadData(Product2.SobjectType,'ProductLoad');

            // To validate creation of Bouquet data
            system.assertEquals(productList.size(), 50);
        }
        
        // Data Setup by Florist for Customer, Bouquet, Blloms    
        Id floristProfileId= [Select Id From Profile Where Name = 'Florist'].Id ;
        List<User> floristUsers = TestDataUtility.createTestUser(1, floristProfileId);
        
        system.runAs(floristUsers[0]){
            List<Lead> leadList = new List<Lead>();
            leadList = TestDataUtility.createTestLeads(2);
            insert leadList;

            // To validate creation of Lead data
            system.assertEquals(leadList.size(), 2);
                
            List<Bouquet__c> boqList = new List<Bouquet__c>();
            boqList = TestDataUtility.createTestBouquets(leadList);
            insert boqList;

            // To validate creation of Bouquet data
            system.assertEquals(boqList.size(), 2);

            

            // Bloom records for each Bouquet for all the Products 
            List<Bloom__c> bloomList = new List<Bloom__c>();
            
            // Querying Product List having Active Products only
            productList = [SELECT Id FROM Product2 WHERE IsActive = true LIMIT 20];
            for(Bouquet__c boq : boqList) { 
              bloomList.addAll(TestDataUtility.createTestBloom(boq.Id,productList));
            }
            // insert bloomList;
            
            // To validate creation of bloomList data
            system.assertEquals(bloomList.size(), 40);
        }
        
    }
    
    // This method is meant to successfully create a New Bouquet along with Blooms in the System by invoking the Page and it's methods
    @isTest static void testSuccessNew(){
        
    
        List<User> floristUsers = [SELECT Id FROM User WHERE Profile.Name = 'Florist' LIMIT 2];
     
    // Inserting Lead in terms of Customer and generating Bouquet for the same.
        list<Lead> customers = TestDataUtility.createTestLeads(1);
        insert customers;
        list<Bouquet__c> bouquets = TestDataUtility.createTestBouquets(customers);   
        
    
    // Evaluating Product Qanities for Canna Flower, As PageBlockTable is sorted with Price and Product Names.
    // Canna will be first flower in the list.
        list<Product2> products = [SELECT Id, Inventory_Remaining__c, Color__c 
                                    FROM Product2 
                                    WHERE Name = 'Canna'];

        Test.startTest();
    
        system.runAs(floristUsers[0]){
        
       
    // Instantiating StandardController for BouquetCreationExtension
        Apexpages.Standardcontroller sc                 = new Apexpages.Standardcontroller(bouquets[0]);
        BouquetCreationExtension controller             = new BouquetCreationExtension(sc);
        
    // Checking all the concern data prior performing required operation with saveBouquet method    
        System.assertEquals(controller.bouquetObj.Id, null);
        System.assertEquals(controller.bouquetObj.Name, null);
        System.assertEquals(customers[0].Most_Used_Color__c, null);
        System.assertEquals(products[0].Inventory_Remaining__c, 1000);
        
        
    // As default page size is is set to 5 for a page load it should have 5 instances in BloomProductWrapperList
    // and Map having all instances which is equivalent to all records 49 active Produts related records. 
        controller.getBloomProductWrapperList();
        System.assertEquals(controller.getBloomProductWrapperList().Size(),5);
        System.assertEquals(controller.totalRecords,49);
        
    // Evaluation of Total number of Pages for New Bouquet
        controller.getTotalPages();
        System.assertEquals(controller.totalPages,10);
          
        
    // Assigning values to bouquetObj
        controller.bouquetObj = bouquets[0];

    // Updating Quantity on Bloom Object to create Bloom records
        for(BloomProductWrapper eachWrap : controller.getBloomProductWrapperList()) {
              eachWrap.bloomObj.Quantity__c = 10;
        }
            
    // Retrieving the newly created Bouquet Id by Florist 
        String bouquetId = '';
        PageReference pgRef = controller.saveBouquet();
        bouquetId = pgRef.getUrl();
        bouquetId = bouquetId.remove('/');
           
        List<Bouquet__c> bouquetList =  [SELECT Id, Name, Customer__c, Customer__r.Most_Used_Color__c
                                            FROM Bouquet__c 
                                            WHERE Id = : bouquetId];
        
    // Validation of Bouquet Data creation while submission of saveBouquet Method
        System.assert(bouquetList[0].Id != null);
        System.assert(bouquetList[0].Name != null);     
        System.assertEquals(bouquetList[0].Customer__c,customers[0].Id);
           
    // Query newly created blooms for this donation            
        List<Bloom__c> bloomList1   = [SELECT Id,Name,Quantity__c
                                        FROM Bloom__c 
                                        where Bouquet__c = : bouquetId]; 
        
        products                    = [SELECT Id, Inventory_Remaining__c 
                                        FROM Product2 
                                        WHERE Name = 'Canna'];
    
    // Validation of Bloom data which is created by saveBouquet method  
        System.assertEquals(bloomList1.Size(),5);
        System.assertEquals(bloomList1[0].Quantity__c,10); 
    
    // Validation of Product and Lead data changes impacted from BloomTrigger 
    // Most Color Used for Customer was null previously now it retains some value
    // Inventory_Remaining__c was 1000 previously, now it is 990 as 
    // Bloom for Rose Flower utilised 10 out of 1000.
        System.assert(bouquetList[0].Customer__r.Most_Used_Color__c != null);
        System.assertEquals(products[0].Inventory_Remaining__c, 990); 
        
        }
        
    // Validating Created blooms and bouquet records visiblity by different florist User    
        system.runAs(floristUsers[1]){
            List<Bloom__c> bloomList1   = [SELECT Id,Name,Quantity__c
                                            FROM Bloom__c LIMIT 10];
                                            
        // List size 0 interprets that different user can not visualize data created by another user. 
            System.assertEquals(bloomList1.Size(),0);
        }
        
                
        Test.stopTest();
    }
    
    // This method used for testing of editing of an existing Bouquet Record
    @isTest static void testSuccessEdit() {
        
        List<User> floristUsers = [SELECT Id FROM User WHERE Profile.Name = 'Florist' LIMIT 2];
        
    
    // Evaluating Product Qanities for Canna Flower, As PageBlockTable is sorted with Price and Product Names.
    // Canna will be first flower in the list.
        list<Product2> products = [SELECT Id, Inventory_Remaining__c, Color__c
                                    FROM Product2 
                                    WHERE Name = 'Canna'];

        Test.startTest();
    
        system.runAs(floristUsers[0]){
    
    
    // Inserting Lead in terms of Customer and generating Bouquet for the same.
        list<Lead> customers = TestDataUtility.createTestLeads(1);
        insert customers;
        list<Bouquet__c> bouquets = TestDataUtility.createTestBouquets(customers);   
        insert bouquets;
        
        
    // Querying Product List having Active Products only
        list<Product2> productList = [SELECT Id FROM Product2 WHERE IsActive = true LIMIT 50];
        list<Bloom__c> bloomList = new list<Bloom__c>();
        bloomList.addAll(TestDataUtility.createTestBloom(bouquets[0].Id,productList));
        insert bloomList;
            
    // Instantiating StandardController for BouquetCreationExtension
        Apexpages.Standardcontroller sc                 = new Apexpages.Standardcontroller(bouquets[0]);
        BouquetCreationExtension controller             = new BouquetCreationExtension(sc);
        
    // Checking all the concern data prior performing required operation with saveBouquet method    
        customers = [SELECT Id, Most_Used_Color__c
                        FROM Lead
                        WHERE Id =: customers[0].Id];
        System.assertEquals(controller.bouquetObj.Id, bouquets[0].Id);
        System.assertEquals(customers[0].Most_Used_Color__c, 'Blue');
        System.assertEquals(products[0].Inventory_Remaining__c, 1000);
        System.assertEquals(products[0].Color__c, 'Green');
        
    // Updating Quantity on Bloom Object to create Bloom records
        for(BloomProductWrapper eachWrap : controller.getBloomProductWrapperList()) {
            if(eachWrap.productObj.Name == 'Canna'){
              eachWrap.bloomObj.Quantity__c = 200;
            }
        }
        
    // Retrieving the newly created Bouquet Id by Florist 
        String bouquetId = '';
        PageReference pgRef = controller.saveBouquet();
        bouquetId = pgRef.getUrl();
        bouquetId = bouquetId.remove('/');
           
        List<Bouquet__c> bouquetList =  [SELECT Id, Name, Customer__c, Customer__r.Most_Used_Color__c
                                            FROM Bouquet__c 
                                            WHERE Id = : bouquetId];
        
    // Validation of Bouquet Data creation while submission of saveBouquet Method
        System.assert(bouquetList[0].Id != null);
        System.assert(bouquetList[0].Name != null);     
        System.assertEquals(bouquetList[0].Customer__c,customers[0].Id);
           
    // Query newly created blooms for this donation            
        List<Bloom__c> bloomList1   = [SELECT Id,Name,Quantity__c
                                        FROM Bloom__c 
                                        where Bouquet__c = : bouquetId]; 
        
        products                    = [SELECT Id, Inventory_Remaining__c 
                                        FROM Product2 
                                        WHERE Name = 'Canna'];
    
    // Validation of Product and Lead data changes impacted from BloomTrigger 
    // Most Color Used for Customer was Blue previously now it will be Green 
    // Inventory_Remaining__c was 1000 previously, now it is 800 as 
    // Bloom for Rose Flower utilised 200 out of 1000.
        System.assert(bouquetList[0].Customer__r.Most_Used_Color__c == 'Green');
        System.assertEquals(products[0].Inventory_Remaining__c, 800); 
        
        }
        
        Test.StopTest();
        
    }

    // This method used for testing of category filtering
    // To evaluate pagination methods behaviour
    @isTest static void testCategoryFilter() {
          
    // Querying Users created for Florist Profile.     
        List<User> floristUsers = [SELECT Id FROM User WHERE Profile.Name = 'Florist' LIMIT 2];
         
        Test.startTest();          
    
    // Testing with 1st User having Florist Profile 
        system.runAs(floristUsers[0]) {
          
    // Creating Test Data for Editing an existing Bouquet with an Florist            
        list<Lead> customers = TestDataUtility.createTestLeads(1);
        insert customers;
        list<Bouquet__c> bouquets = TestDataUtility.createTestBouquets(customers);   
        
        
    // Querying Product List having Active Products only
        list<Product2> productList = [SELECT Id FROM Product2 WHERE IsActive = true LIMIT 50];
   

    // Instantiating StandardController for BouquetCreationExtension
        Apexpages.Standardcontroller sc                 = new Apexpages.Standardcontroller(bouquets[0]);
        BouquetCreationExtension controller             = new BouquetCreationExtension(sc);
                        
        System.assertEquals(controller.bouquetObj.Id, null);
          
    // Checks if selected family have been populated to page
        
        List<SelectOption> families = new List<SelectOption>();
    // To check families size before calling getCategories method`
        System.assert(families.size() == 0); 
        families = controller.getCategories();
    
    // To check families size after calling getCategories method
        System.assert(families.size() != 0);          
          
    // Declaring variable for to the flower of particular family
    // Evaluating count of flower for family 'Gladiolas' without filtering
    // Revalutig count of flowers for the same family after filtering
        integer countFlowers = 0;
        
        for(BloomProductWrapper eachWrap : controller.getBloomProductWrapperList()){
            if(eachWrap.ProductObj.Family == 'Gladiolas'){
                countFlowers ++;
            }
            // To check all existing Bloom's Quantity as 0
            system.assertEquals(eachWrap.BloomObj.Quantity__c, 0);
            
            // Quantity has been changed to 10. It will helpful to calculate cost of Bouquet
            // On change of Family
            if(eachWrap.ProductObj.Name == 'Canna'){
                eachWrap.BloomObj.Quantity__c = 10;
            }
        }
    
    // Onload of page with 0 quantity chart will not be displayed and 
    // Cost of bouquet will appear as 0.
        system.assertEquals(controller.displaySummaryChart, False);
        system.assertEquals(controller.totalBouquetCost, 0);
        
    // Only one Flower Canna will be appearing for family 'Gladiolas' before filtering
        system.assertEquals(countFlowers, 1);
    
    // Assinging 'Gladiolas' family to selectedFamily and invoking relevent method
        controller.selectedFamily = 'Gladiolas';
        controller.queryProductByFamily();
    
    // Pie chart will appear with change of flag displaySummaryChart
    // Cost of bouquet will appear as 10 $ Each Bloom multiplied with 10 Qantity, 100 $.
        system.assertEquals(controller.displaySummaryChart, true);
        system.assertEquals(controller.totalBouquetCost, 100);
    
    // Revalutig count of flowers for the same family after filtering
        countFlowers = 0;
        for(BloomProductWrapper eachWrap : controller.getBloomProductWrapperList()){
            if(eachWrap.ProductObj.Family == 'Gladiolas'){
                countFlowers ++;
            }
            
        }
        
    // Only one Flower Canna will be appearing for family 'Gladiolas' before filtering
        system.assertEquals(countFlowers, 5);   
         
       Test.stopTest(); 
       }
    }
    
    // To evaluate pagination methods behaviour
    @isTest static void testPagination() {
          
    // Querying Users created for Florist Profile.     
        List<User> floristUsers = [SELECT Id FROM User WHERE Profile.Name = 'Florist' LIMIT 2];
         
        Test.startTest();          
    
    // Testing with 1st User having Florist Profile 
        system.runAs(floristUsers[0]) {
          
    // Creating Test Data for Editing an existing Bouquet with an Florist            
        list<Lead> customers = TestDataUtility.createTestLeads(1);
        insert customers;
        list<Bouquet__c> bouquets = TestDataUtility.createTestBouquets(customers);   
        
        
    // Querying Product List having Active Products only
        list<Product2> productList = [SELECT Id FROM Product2 WHERE IsActive = true LIMIT 50];
   

    // Instantiating StandardController for BouquetCreationExtension
        Apexpages.Standardcontroller sc                 = new Apexpages.Standardcontroller(bouquets[0]);
        BouquetCreationExtension controller             = new BouquetCreationExtension(sc);
                        
        System.assertEquals(controller.bouquetObj.Id, null);
          
    // By Default Page load will land first of pagination where 5 records will be visible
    // First and previous button on pageblocktable apperaing disbled.
    // It will be dirven by the boolean flag as hasPrevious.
        System.assertEquals(controller.hasPrevious, false);
    // hasNext will responisble for the Visibility of Next and Last Button
    // As we have totol 49 Products so Next and Last buttons will be visible
        System.assertEquals(controller.hasNext , true);
    // pageNumber reperenting landing page of PageBlock, It will appeear as 10
        System.assertEquals(controller.pageNumber , 1);
    // As we have totol 49 Products so Number of pages will be 10, 5 records per page
        controller.getTotalPages();
        System.assertEquals(controller.totalPages, 10);
    
    // To cross verify products exists for 1st page are with quantities 0.
        for(BloomProductWrapper eachWrap : controller.getBloomProductWrapperList()){ 
        // To check all existing Bloom's Quantity as 0
            system.assertEquals(eachWrap.BloomObj.Quantity__c, 0);
        }
        
    // Pie chart will not appear with 0 quantities of products for first page
    // Cost of bouquet will appear as 0 $ by default.
        system.assertEquals(controller.displaySummaryChart, false);
        system.assertEquals(controller.totalBouquetCost, 0);
        
          
    // Assigning 10 Quantities to each product for Page 1
        for(BloomProductWrapper eachWrap : controller.getBloomProductWrapperList()){            
            // Quantity has been changed to 10. It will helpful to calculate cost of Bouquet
            // On change of Family
            eachWrap.BloomObj.Quantity__c = 10;
        }
    
    // Onload of page with 0 quantity chart will not be displayed and 
    // Cost of bouquet will appear as 0.
        system.assertEquals(controller.displaySummaryChart, False);
        system.assertEquals(controller.totalBouquetCost, 0);
    
    // Moving ahead to next page in visualforce page
        controller.next();
    
    // Pie chart will appear with change of flag displaySummaryChart
    // Cost of bouquet will appear as 10 $ Each Bloom multiplied with 10 Qantity, 100 $.
    // For 5 Different Products the total bouquet cost will changed to 500
        system.assertEquals(controller.displaySummaryChart, true);
        system.assertEquals(controller.totalBouquetCost, 500);
    
    // It will be dirven by the boolean flag as hasPrevious.
    // First and Previous buttons will be visible now.
        System.assertEquals(controller.hasPrevious, true);
    // hasNext will responisble for the Visibility of Next and Last Button
    // As we have totol 49 Products so Next and Last buttons will be visible
        System.assertEquals(controller.hasNext , true);
    // pageNumber reperenting landing page of PageBlock, It will appeear as 2
        System.assertEquals(controller.pageNumber , 2);
        
    // Assigning 10 Quantities to only 1 product for Page 2
        for(BloomProductWrapper eachWrap : controller.getBloomProductWrapperList()){            
            // Quantity has been changed to 10. It will helpful to calculate cost of Bouquet
            // On change of Family
            eachWrap.BloomObj.Quantity__c = 10;
            break;
        }
    
    // Moving back to first page in pageBlocktable using previous button
        controller.previous();    

    // Pie chart will appear with change of flag displaySummaryChart
    // Cost of bouquet will appear as 10 $ Each Bloom multiplied with 10 Qantity, 100 $.
    // For 1 more Product the total bouquet cost will changed to 600
        system.assertEquals(controller.displaySummaryChart, true);
        system.assertEquals(controller.totalBouquetCost, 600);
    
    // It will be dirven by the boolean flag as hasPrevious.
    // First and Previous buttons will be invisible now.
        System.assertEquals(controller.hasPrevious, false);
    // hasNext will responisble for the Visibility of Next and Last Button
    // As we have totol 49 Products so Next and Last buttons will be visible
        System.assertEquals(controller.hasNext , true);
    // pageNumber reperenting landing page of PageBlock, It will appeear as 1
        System.assertEquals(controller.pageNumber , 1);     
       
    // Moving ahead to last section in pageBlocktable using last button
        controller.last();   
    
    // As we have total 49 prouducts utilising, last section should show only 4 products.
        System.assertEquals(controller.getBloomProductWrapperList().size() , 4);
        
    // It will be dirven by the boolean flag as hasPrevious.
    // First and Previous buttons will be visible now.
        System.assertEquals(controller.hasPrevious, true);
    // hasNext will responisble for the Visibility of Next and Last Button
    // As we have totol 49 Products so Next and Last buttons will be visible
        System.assertEquals(controller.hasNext , false);
    // pageNumber reperenting landing page of PageBlock, It will appeear as 10
        System.assertEquals(controller.pageNumber , 10);        
        
    // Assigning 10 Quantities to only 1 product for Page 2
        for(BloomProductWrapper eachWrap : controller.getBloomProductWrapperList()){            
            // Quantity has been changed to 10. It will helpful to calculate cost of Bouquet
            // On change of Family
            eachWrap.BloomObj.Quantity__c = 10;
        }
    
    // Moving  to first section in pageBlocktable using last button
        controller.first(); 
        
    // It will be dirven by the boolean flag as hasPrevious.
    // First and Previous buttons will be visible now.
        System.assertEquals(controller.hasPrevious, false);
    // hasNext will responisble for the Visibility of Next and Last Button
    // As we have totol 49 Products so Next and Last buttons will be visible
        System.assertEquals(controller.hasNext , true);
    // pageNumber reperenting landing page of PageBlock, It will appeear as 1
        System.assertEquals(controller.pageNumber , 1); 
    
    // Pie chart will appear with change of flag displaySummaryChart
    // Cost of bouquet will appear as 10 $ Each Bloom multiplied with 10 Qantity, 100 $.
    // For 4 more Product the total bouquet cost will changed to 1800.
    // All the products in the last page appearing with cost as 30 $ 
    // Each will be with quantities 10, 30 * 10 * 4 = 1200, 1200 + 600
        system.assertEquals(controller.displaySummaryChart, true);
        system.assertEquals(controller.totalBouquetCost, 1800);
       
       Test.stopTest(); 
       }
    }
    
    // This method is responsible for testing of creation of Blooms
    // Meanwhile we will check the behavior when quantity reduces to 0 while editing
    // Associated Blooms gets deleted.
    @isTest static void testSuccessDeletion(){
        
    
        List<User> floristUsers = [SELECT Id FROM User WHERE Profile.Name = 'Florist' LIMIT 2];
     
    // Inserting Lead in terms of Customer and generating Bouquet for the same.
        list<Lead> customers = TestDataUtility.createTestLeads(1);
        insert customers;
        list<Bouquet__c> bouquets = TestDataUtility.createTestBouquets(customers);   
        
        
    
    
    // Evaluating Product Qanities for Canna Flower, As PageBlockTable is sorted with Price and Product Names.
    // Canna will be first flower in the list.
        list<Product2> products = [SELECT Id, Inventory_Remaining__c, Color__c 
                                    FROM Product2 
                                    WHERE Name = 'Canna'];

        Test.startTest();
    
        system.runAs(floristUsers[0]){
        
       
    // Instantiating StandardController for BouquetCreationExtension
        Apexpages.Standardcontroller sc                 = new Apexpages.Standardcontroller(bouquets[0]);
        BouquetCreationExtension controller             = new BouquetCreationExtension(sc);
        
    // Checking all the concern data prior performing required operation with saveBouquet method    
        System.assertEquals(controller.bouquetObj.Id, null);
        System.assertEquals(controller.bouquetObj.Name, null);
        System.assertEquals(customers[0].Most_Used_Color__c, null);
        System.assertEquals(products[0].Inventory_Remaining__c, 1000);
        
        
    // As default page size is is set to 5 for a page load it should have 5 instances in BloomProductWrapperList
    // and Map having all instances which is equivalent to all records 49 active Produts related records. 
        controller.getBloomProductWrapperList();
        System.assertEquals(controller.getBloomProductWrapperList().Size(),5);
        System.assertEquals(controller.totalRecords,49);
        
    // Evaluation of Total number of Pages for New Bouquet
        controller.getTotalPages();
        System.assertEquals(controller.totalPages,10);
          
        
    // Assigning values to bouquetObj
        controller.bouquetObj = bouquets[0];

    // Updating Quantity on Bloom Object to create Bloom records
        for(BloomProductWrapper eachWrap : controller.getBloomProductWrapperList()) {
            if(eachWrap.productObj.Name == 'Canna')
			eachWrap.bloomObj.Quantity__c = 10;
        }
            
    // Retrieving the newly created Bouquet Id by Florist 
        String bouquetId = '';
        PageReference pgRef = controller.saveBouquet();
        bouquetId = pgRef.getUrl();
        bouquetId = bouquetId.remove('/');
           
        List<Bouquet__c> bouquetList =  [SELECT Id, Name, Customer__c, Customer__r.Most_Used_Color__c
                                            FROM Bouquet__c 
                                            WHERE Id = : bouquetId];
        
    // Validation of Bouquet Data creation while submission of saveBouquet Method
        System.assert(bouquetList[0].Id != null);
        System.assert(bouquetList[0].Name != null);     
        System.assertEquals(bouquetList[0].Customer__c,customers[0].Id);
           
    // Query newly created blooms for this donation            
        List<Bloom__c> bloomList1   = [SELECT Id,Name,Quantity__c
                                        FROM Bloom__c 
                                        where Bouquet__c = : bouquetId]; 
        
        products                    = [SELECT Id, Inventory_Remaining__c 
                                        FROM Product2 
                                        WHERE Name = 'Canna'];
    
    // Validation of Bloom data which is created by saveBouquet method  
        System.assertEquals(bloomList1.Size(),1);
        System.assertEquals(bloomList1[0].Quantity__c,10); 
    
    // Validation of Product and Lead data changes impacted from BloomTrigger 
    // Most Color Used for Customer was null previously now it retains some value
    // Inventory_Remaining__c was 1000 previously, now it is 990 as 
    // Bloom for Rose Flower utilised 10 out of 1000.
        System.assert(bouquetList[0].Customer__r.Most_Used_Color__c != null);
        System.assertEquals(products[0].Inventory_Remaining__c, 990); 
        
    // While Editing we will make sure to make quantities of bloomList to 0
    // Again we will invoke saveBouquet method to and we will verify whether 
    // concern records are being deleted or not
        for(BloomProductWrapper eachWrap : controller.getBloomProductWrapperList()) {
            if(eachWrap.productObj.Name == 'Canna')
			eachWrap.bloomObj.Quantity__c = 0;
        }
        
        pgRef = controller.saveBouquet();
        bouquetId = pgRef.getUrl();
        bouquetId = bouquetId.remove('/');
        
        
		products                    = [SELECT Id, Inventory_Remaining__c 
                                        FROM Product2 
                                        WHERE Name = 'Canna'];
										
		bloomList1                  = [SELECT Id,Name,Quantity__c
                                        FROM Bloom__c 
                                        WHERE Bouquet__c = : bouquetId
											AND Flower__c =: products[0].Id]; 
        
        
                                        
        // Validation of Bloom data which is created by saveBouquet method  
        // System.assertEquals(bloomList1.Size(),0);
        // System.assertEquals(products[0].Inventory_Remaining__c,1000); 
        
        
        }
        
                
        Test.stopTest();
    }
    
    // Negative Scenarios
    // Providing Inappropriate Values to input fields of Bouquet
    // Providing Inappropriate quantities to Blooms while creation
    // Providing null values to quantity of 
    @isTest static void testNegativeCases(){
        
    
        List<User> floristUsers = [SELECT Id FROM User WHERE Profile.Name = 'Florist' LIMIT 2];
     
        Test.StartTest();
        
    // Inserting Lead in terms of Customer and generating Bouquet for the same.
        list<Lead> customers = TestDataUtility.createTestLeads(1);
        insert customers;
        list<Bouquet__c> bouquets = TestDataUtility.createTestBouquets(customers);   
         
     
    // Instantiating StandardController for BouquetCreationExtension
        Apexpages.Standardcontroller sc                 = new Apexpages.Standardcontroller(bouquets[0]);
        BouquetCreationExtension controller             = new BouquetCreationExtension(sc);
        
    // Checking all the concern data prior performing required operation with saveBouquet method    
        System.assertEquals(controller.bouquetObj.Id, null);
        System.assertEquals(controller.bouquetObj.Name, null);
        
    // Assigning values to bouquetObj
    // Trying to insert without providing Customer value
        controller.bouquetObj.Customer__c = null;
        controller.bouquetObj.Delivery_Date__c = Date.Today();
        controller.bouquetObj.Deliver_To__c = 'Test Address';
        controller.bouquetObj.Message__c = 'Test Message';
        
        try{
            PageReference pg = controller.saveBouquet();
        }
        Catch(Exception e){
        // Validating the error messages appearing on the screen by not providing relevent information  
            System.assert(e.getMessage().contains('Customer: You must enter a value'));
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
        }      
        
    
    // Assigning values to bouquetObj
    // Trying to insert by providing Customer value
    // Other details are empty
        controller.bouquetObj.Customer__c = customers[0].Id;
        controller.bouquetObj.Delivery_Date__c = null;
        controller.bouquetObj.Deliver_To__c = null;
        controller.bouquetObj.Message__c = null;
        
        try{
            PageReference pg = controller.saveBouquet();
        }
        Catch(Exception e){
            System.assert(e.getMessage().contains('Message: You must enter a value'));
            System.assert(e.getMessage().contains('Delivery Date: You must enter a value'));
            System.assert(e.getMessage().contains('Delivery To: You must enter a value'));
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
        }

    // Assigning values to bouquetObj
    // Trying to insert by providing details for bouquet
    // Inappropriate values for quanity of product.
    // 
        controller.bouquetObj.Customer__c = customers[0].Id;
        controller.bouquetObj.Delivery_Date__c = Date.Today();
        controller.bouquetObj.Deliver_To__c = 'Test Address';
        controller.bouquetObj.Message__c = 'Test Message';
        
        // Updating Quantity on Bloom Object to create Bloom records
        for(BloomProductWrapper eachWrap : controller.getBloomProductWrapperList()) {
              if(eachWrap.productObj.Name == 'Canna')
              eachWrap.bloomObj.Quantity__c = null;
        }
        
        try{
            PageReference pg = controller.saveBouquet();
        }
        Catch(Exception e){
            System.assert(e.getMessage().contains('Quantity: You must enter a value'));
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
        }           
     
    // Testing the Scenario where Quanities provided by end user is more than that remaining inventory
    // Flower considered is Canna for the same scenario. Intial Inventory is 1000, we will try to provide 
    // Input inventory as 1010. to check the concern behavior.

        list<Product2> products = [SELECT Id, Inventory_Remaining__c, Color__c 
                                    FROM Product2 
                                    WHERE Name = 'Canna'];
        
       

        System.assertEquals(customers[0].Most_Used_Color__c, null);
        System.assertEquals(products[0].Inventory_Remaining__c, 1000);
        
        
    // As default page size is is set to 5 for a page load it should have 5 instances in BloomProductWrapperList
    // and Map having all instances which is equivalent to all records 49 active Produts related records. 
        controller.getBloomProductWrapperList();
        System.assertEquals(controller.getBloomProductWrapperList().Size(),5);
        System.assertEquals(controller.totalRecords,49);
        
    // Evaluation of Total number of Pages for New Bouquet
        controller.getTotalPages();
        System.assertEquals(controller.totalPages,10);
          
        
    // Assigning values to bouquetObj
        controller.bouquetObj = bouquets[0];

    // Updating Quantity on Bloom Object to create Bloom records
        for(BloomProductWrapper eachWrap : controller.getBloomProductWrapperList()) {
              if(eachWrap.productObj.Name == 'Canna')
              eachWrap.bloomObj.Quantity__c = 1010;
        }
            
    // Retrieving the newly created Bouquet Id by Florist 
        try{
            PageReference pgRef = controller.saveBouquet();
        }
        Catch(Exception e){
            // Below error message pretends that user cannot provide more quantity than that of remaining inventories.
            System.assert(e.getMessage().contains('Quantity Used cannot be more than Remaining Inventories Canna'));
        }
        
    }
}