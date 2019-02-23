trigger MaintenanceRequest on Case (before update, after update) {
    // call MaintenanceRequestHelper.updateWorkOrders  
    
    if(trigger.isAfter && trigger.isUpdate) {
        System.debug('MaintenanceRequest After.update start #####');
        MaintenanceRequestHelper.updateWorkOrders(trigger.oldMap,trigger.new);
        System.debug('MaintenanceRequest After.update end #####');
    }
}