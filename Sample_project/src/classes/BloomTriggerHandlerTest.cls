//*****************************************************************************************************
    // Name         : BloomTriggerHandlerTest 
    // Created by   : Candidate
    // Description  : This class is used for Validation of BloomTriggerHandler 
    //                by performing various activities like Insert/Update/Delete/Undelete 
    //                and Bulk operations/Neagtive scenarios.
    //******************************************************************************************************

    @isTest
    private class BloomTriggerHandlerTest {

        // This method is used to create Centralised Test data so that 
        // same is accesible in all the test methods written in this test class.
        @testSetup static void setupData() {
            
            List<Lead> leadList = new List<Lead>();
            leadList = TestDataUtility.createTestLeads(2);
            insert leadList;
            
            system.AssertEquals(leadList.size(), 2);

            List<Bouquet__c> boqList = new List<Bouquet__c>();
            boqList = TestDataUtility.createTestBouquets(leadList);
            insert boqList;

            system.AssertEquals(boqList.size(), 2);
            
            // 5 Products each in 3 different Colors.
            List<Product2> productList = new List<Product2>();
            productList.addAll(TestDataUtility.createTestProducts(5,'Blue'));
            productList.addAll(TestDataUtility.createTestProducts(5,'White'));
            productList.addAll(TestDataUtility.createTestProducts(5,'Red'));
            insert productList; 

            // Bloom records for each Bouquet for all the Products
            // Inserted blooms are to be considered with 10 quanitties 
            // for each Flower.
            List<Bloom__c> bloomList = new List<Bloom__c>();
            for(Bouquet__c boq : boqList) { 
                bloomList.addAll(TestDataUtility.createTestBloom(boq.Id,productList));
            }
            insert bloomList; 

            system.AssertEquals(bloomList.size(), 30);          
        }

        // This method is used to update Bloom Quantity on a Single Record 
        // and observe changes on the Inventory used on Product2 Object
        @isTest static void testUpdatebloomQuantity() {  
            List<Bloom__c> bloomList = [SELECT Id,Name,Quantity__c,Flower__c, Flower__r.Color__c, Bouquet__r.Customer__c from Bloom__c];
            
            Test.startTest();

        //Test for "Inventory Reamaining" on Product2 Object
            Product2 flower = [Select Id,Name,Inventory_Remaining__c from Product2 
                                        Where Id = : bloomList[0].Flower__c];
            
        // Observing Inventory User Quantity prior to update record. 
        // Remaining Inventory is 980, as it used by two different blooms 
        // of different bouquets
            System.assertEquals(flower.Inventory_Remaining__c,980);
        // Validating whether quantity used by bloom is 10.
            System.assertEquals(bloomList[0].Quantity__c,10);

        //Incrementing bloom quantity with 10
            bloomList[0].Quantity__c = 20;
            update bloomList[0];  
                                  
            flower = [Select Id,Name,Inventory_Remaining__c from Product2 
                                        Where Id = : bloomList[0].Flower__c];

        // Observing Inventory User Quantity prior to update record. 
            System.assertEquals(flower.Inventory_Remaining__c,970);
        // Validating whether quantity used by bloom is 20 after updating from trigger.
            System.assertEquals(bloomList[0].Quantity__c,20);  
            
        // Deleting one of the bloom, meanwhile we will validate quantity flower remaining 
        // increasing.
            delete bloomList[0];
            
            flower = [Select Id,Name,Inventory_Remaining__c from Product2 
                                        Where Id = : bloomList[0].Flower__c];
                                        
        // Observing Inventory Remaining Quantity  after deleteion of Bloom . 
            System.assertEquals(flower.Inventory_Remaining__c,990);
            
            bloomList = [SELECT Id, Quantity__c
                            FROM Bloom__c
                            WHERE Flower__c =: flower.Id];
            
            delete bloomList;
            
            bloomList = [SELECT Id, Quantity__c
                            FROM Bloom__c
                            WHERE Flower__c =: flower.Id];
                            
            flower = [Select Id,Name,Inventory_Remaining__c from Product2 
                                        Where Id = : flower.Id];
                            
        // Observing Inventory Remaining Quantity  after deleteion of Bloom . 
            System.assertEquals(bloomList.size(),0); 
            System.assertEquals(flower.Inventory_Remaining__c,1000);   

            Test.stopTest();  

        }

        // This method is used to update color on a bloomList 
        // and observe changes on Most Used Color on Lead object.
        @isTest static void testUpdatebloomListColor() {  
            List<Bloom__c> bloomList = [SELECT Id,Name,Quantity__c,Flower__c, Flower__r.Color__c, Bouquet__r.Customer__c from Bloom__c];
            
            Test.startTest();

        // Test for "Most Used Color" on Lead object
        // As of now Most Used Color is Blue
        // Initial load has been done for blooms with same quantities with same flowers
        // each Bouquet. So quantity will be similar for the Color Blue, White and Red
        // As of Similar quanitity, Colors will be sorted down alphabatically to populate
        // most used color field on Lead Object, Outcome will appear as Blue
            Lead customer = [SELECT Id,Most_Used_Color__c FROM Lead
                                    WHERE Id = : bloomList[0].Bouquet__r.Customer__c];
            
            
        //"Most Used Color" on Lead object changes from Red to White prior to update
            System.assertEquals(customer.Most_Used_Color__c,'Blue');

        // Updating bloomList and making Blue color records to 0 quanitity
            for(Bloom__c eachBloom : bloomList){
                if(eachBloom.Flower__r.Color__c == 'Blue'){
                    eachBloom.Quantity__c = 0;
                }
            }
            
        // update bloomList;  
            update bloomList;                      

        //"Most Used Color" on Lead object changes from Blue to Red
        // Bloom list are existing with Red and White colored flowers with same quanitity
        // Alphabatically Red will ahead of White for the Most User Color Field on Lead
            customer = [SELECT Id,Most_Used_Color__c FROM Lead
                                    WHERE Id = : bloomList[0].Bouquet__r.Customer__c];
            System.assertEquals(customer.Most_Used_Color__c,'Red');

        // Similarly Updating bloomList and making Red color records to 0 quanitity 
            for(Bloom__c eachBloom : bloomList){
                if(eachBloom.Flower__r.Color__c == 'Red'){
                    eachBloom.Quantity__c = 0;
                }
            }
            
        // update bloomList;  
            update bloomList;                      

        //"Most Used Color" on Lead object changes from Red to White
        // Bloom list are existing with White colored flowers with same quanitity
        // Only White Colored Flowered are available, most used flower will be White 
            customer = [SELECT Id,Most_Used_Color__c FROM Lead
                                    WHERE Id = : bloomList[0].Bouquet__r.Customer__c];
            System.assertEquals(customer.Most_Used_Color__c,'White');          

            Test.stopTest();  

        }

        
        // This method is used to test update Bloom Quantity on the bulk data 
        // and observe changes on Inventory_Used__c/Most_Used_Color__c
        @isTest static void testBulkBloomQuantityUpdate() {

            List<Bloom__c> bloomList = [SELECT Id,Name,Quantity__c,Flower__c, Bouquet__r.Customer__c from Bloom__c];                    
            Test.startTest();    

            Product2 flower = [Select Id,Name,Inventory_Remaining__c from Product2
                                        Where Id = : bloomList[0].Flower__c];

        // Validating Remaining Inventories for all the flowers after Blooms 
        // created for 2 bouquets with quantities each with 10.
        // Same flower is being used by two bouquets with quantity 10 each.
        // Remaining Inventories for all the flowers will be 980.
            for(Product2 eachFlower : [Select Id,Name,Inventory_Remaining__c from Product2]){
                System.assertEquals(flower.Inventory_Remaining__c,980);             
            }
            
            
        // Evaluating Most Used Color for relevant Flower.
            Lead customers1 = [SELECT Id,Most_Used_Color__c FROM Lead
                                        WHERE Id = : bloomList[0].Bouquet__r.Customer__c];

            System.assertEquals(customers1.Most_Used_Color__c,'Blue');

        // Changing quanities for all the blooms with 10 quantities each.
            list<Bloom__c> listBloomToUpdate = new list<Bloom__c>();
            for(Bloom__c bloom : bloomList){
                bloom.Quantity__c = 20;  
                listBloomToUpdate.add(bloom);
            }
            
            try{
                update listBloomToUpdate;   
            }
            catch(Exception e){
                system.debug( ' @@ exception @@ ' + e);
            }
            
        // Validating Remaining Inventories for all the flowers after Blooms 
        // created for 2 bouquets with quantities each with 10.
        // Same flower is being used by two bouquets with quantity 10 each.
        // Previously the quantity for each Flower was 980. After updation
        // Remaining Inventories for all the flowers will be 960.
            for(Product2 eachFlower : [Select Id,Name,Inventory_Remaining__c from Product2]){
                System.assertEquals(eachFlower.Inventory_Remaining__c,960);             
            }

            Lead customer = [SELECT Id,Most_Used_Color__c FROM Lead
                                        WHERE Id = : bloomList[0].Bouquet__r.Customer__c];

            System.assertEquals(customer.Most_Used_Color__c,'Blue');

            Test.stopTest();     
        }
        
        
        // This method is used to update Bouquet/Product(Flower) on Bloom records
        // and observe changes on the Inventory Used and Most Used Color
        // Assumption: This use case can be handled in case of Data Loader only,
        // through UI we cannot change the Product.
        @isTest static void testUpdateBlooms() {
            
            List<Bloom__c> bloomList = [SELECT Id,Name,Quantity__c,Flower__c, Bouquet__r.Customer__r.Most_Used_Color__c,Bouquet__r.Name 
                                            FROM Bloom__c];
            
            List<Bloom__c> bloomListCust1 = new List<Bloom__c>();
            List<Bloom__c> bloomListCust2 = new List<Bloom__c>();
            
            Test.startTest();
            
            list<Lead> customers    = [SELECT Id,Most_Used_Color__c FROM Lead];

        // As of now Most Used Color is Blue
        // Initial load has been done for blooms with same quantities with same flowers
        // each Bouquet. So quantity will be similar for the Color Blue, White and Red
        
        // Customer-1
            System.assertEquals(customers[0].Most_Used_Color__c,'Blue');
        // Customer-2
            System.assertEquals(customers[1].Most_Used_Color__c,'Blue');
        
        // Changing Bloom Quantity for Customer-1
            bloomList       = [SELECT Id,Name,Quantity__c,Flower__c
                                FROM Bloom__c
                                WHERE Bouquet__r.Customer__c =: customers[0].Id
                                    AND Flower__r.Color__c = 'Red'];
            
            
            bloomList[0].Quantity__c = 100;
            
            update bloomList[0];
            
            bloomListCust1       = [SELECT Id, Name, Quantity__c, Flower__c, Bouquet__c, Bouquet__r.Customer__r.Most_Used_Color__c
                                        FROM Bloom__c
                                        WHERE Id =: bloomList[0].Id];
          
        // Validating Most Used Color Customer-1                                 
            System.assertEquals(bloomListCust1[0].Bouquet__r.Customer__r.Most_Used_Color__c,'Red');
        
        
        //"Most Used Color" on Lead object changes from Red to White
            Lead customer2 = [SELECT Id, Most_Used_Color__c FROM Lead
                                    WHERE Id = : customers[1].Id];
        // Validating Most Used Color Customer-2 
            System.assertEquals(customer2.Most_Used_Color__c,'Blue');
         
        
        // Querying BloomList for customer2,  
            bloomListCust2       = [SELECT Id, Name, Quantity__c, Flower__c, Bouquet__c, Bouquet__r.Customer__r.Most_Used_Color__c
                                        FROM Bloom__c
                                        WHERE  Bouquet__r.Customer__c =: customer2.Id];
                                        
                                        
        // To replace Bouquet for Bloom with customer-2 by the bouquet for Bloom with Customer-1
            // bloomListCust2[0].Bouquet__c = bloomListCust1[0].Bouquet__c;
            bloomListCust1[0].Bouquet__c = bloomListCust2[0].Bouquet__c;
            update bloomListCust1[0];
            
        //"Most Used Color" on Lead object changes from Red to White
            Lead customer1 = [SELECT Id, Most_Used_Color__c FROM Lead
                                    WHERE Id = : customers[0].Id];
        // Validating Most Used Color Customer-1 
            System.assertEquals(customer1.Most_Used_Color__c,'Blue');

        //"Most Used Color" on Lead object changes from Red to White
            customer2 = [SELECT Id, Most_Used_Color__c FROM Lead
                                    WHERE Id = : customer2.Id];
        // Validating Most Used Color Customer-2 
            System.assertEquals(customer2.Most_Used_Color__c,'Red');

        // Quering a flower with Blue color
            Product2 blueFlower = [SELECT Id 
                                    FROM Product2
                                    WHERE Color__c = 'Blue' LIMIT 1];
            bloomListCust1[0].Flower__c = blueFlower.Id;
            update bloomListCust1[0];
            
            Test.stopTest();

        }

        

        // This method is used to test failure of Bloom record Creation 
        @isTest static void testBloomCreationFailure() {

            List<Bloom__c> bloomList = [SELECT Id,Name,Quantity__c,Flower__c, Flower__r.Color__c, Bouquet__r.Customer__c from Bloom__c];
            List<Bloom__c> BloomListToInsert = new List<Bloom__c>();

            Test.startTest();

        // Preparing Test Data for Bloom records having more quantity than Remaining inventory
            for(Integer i = 0; i < 5; i++) {
                BloomListToInsert.add(TestDataUtility.createTestSingleBloom(BloomList[0].Bouquet__c,BloomList[0].Flower__c,1000*(i+1)));  
            }

            try {
            // Creating Single Bloom record   
                insert BloomListToInsert[0];
            }
            catch(Exception e) {
            //Insert failed because of less Remaining inventory than quantity
                System.assert(e.getMessage().contains('You may not use more Inventory than is Remaining'));
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
            }

            try {
            // Creating Bulk Bloom records    
                insert BloomListToInsert;
            }
            catch(Exception e) {
                System.assert(e.getMessage().contains('You may not use more Inventory than is Remaining'));
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
            }

            Test.stopTest();
        }

    }