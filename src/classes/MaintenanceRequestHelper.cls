public class MaintenanceRequestHelper {
    
    public static void updateWorkOrders(Map<id, Case> oldMap, List<Case> newCases){
        
        List<Id> updCaseIdList = new List<Id>();

        for(Case cs : newCases) {
            // old case
            Case oldCs = oldMap.get(cs.Id);
            // check case status & type
            if(cs.status == 'Closed' && oldCs.status != cs.status) {
                if(cs.type == 'Repair' || cs.type == 'Routine Maintenance'){ // Repair or Routine Maintenance
                    updCaseIdList.add(cs.Id);
                }
            }
        }

        if (updCaseIdList.size() > 0) {
            System.debug('###updCaseIdList.size = ' + updCaseIdList.size());
            // add to new
            insertNewCase(updCaseIdList);

        }        
        // update workorders
        
    }        

    private static void insertNewCase (List<Id> newCaseIds){

        System.debug('##### insertNewCase Start #####');
        Map<id, Integer> dueDateMap = new Map<id, Integer> ();
 
        List<Case> caseList = [Select Id, Vehicle__c, Equipment__c, 
                                    (Select Equipment__r.Maintenance_Cycle__c,Maintenance_Request__c From Work_Parts__r) 
                                    From Case 
                                    Where id in :newCaseIds];
        
        
        // map old id & new id
        Map<id, Case> caseIdNewCaseMap= new Map<id, Case>();
        // map id & workparts
        Map<id, list<Work_Part__c>> caseWorkPartsMap= new Map<id, list<Work_Part__c>>();
        // new case
        List<Case> insertCaseList = new List<Case>();
        for (Case cs : caseList) {
            // put caseWorkPartsMap
            caseWorkPartsMap.put(cs.id, cs.Work_Parts__r);
            // maintenence cycle
            Integer shortSpan = getShortSpan(cs.Work_Parts__r);
            Case newCs = new Case(  Subject = 'New maintenance',
                                    Vehicle__c = cs.Vehicle__c,
                                    Type = 'Routine Maintenance',
                                    Equipment__c = cs.Equipment__c,

                                    Date_Reported__c = System.Today()
            );         
            insertCaseList.add(newCs);
            // put caseIdNewCaseMap
            caseIdNewCaseMap.put(cs.id, newCs);
        } 

        // insert case
        if (insertCaseList.size() > 0) {
            System.debug('##### addCaseList.size = ' + insertCaseList.size());
            insert insertCaseList;
        }


        // work parts
        List<Work_Part__c> updateWorkPartsList = new List<Work_Part__c>();
        for (Id csId : caseWorkPartsMap.keyset()) {
            for (Work_Part__c wp : caseWorkPartsMap.get(csId)){
                wp.Maintenance_Request__c = caseIdNewCaseMap.get(csId).Id;
                updateWorkPartsList.add(wp);
            }            
        }

        // insert case
        if (updateWorkPartsList.size() > 0) {
            System.debug('##### updateWorkPartsList.size = ' + updateWorkPartsList.size());
            update updateWorkPartsList;
        }
    }

    private static Integer getShortSpan(list<Work_Part__c> maintenenceCycles){
        Integer shortSpan = 0;
        list<Integer> shortSpans = new list<Integer>();
        for (Work_Part__c wp : maintenenceCycles){
            shortSpans.add(Integer.valueof(wp.Equipment__r.Maintenance_Cycle__c));
        }
        if(shortSpans.size() > 0 ){
            shortSpans.sort();
            shortSpan= shortSpans.get(0);
        }
        return shortSpan;
    } 
    
}