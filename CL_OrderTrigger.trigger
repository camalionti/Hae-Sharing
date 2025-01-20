trigger CL_OrderTrigger on Order__c (after insert, after update) {
    if (trigger.isInsert || trigger.isUndelete) {
        CL_OrderTriggerHandler.afterInsert(trigger.new);
    } else if (trigger.isUpdate) {
        CL_OrderTriggerHandler.afterUpdate(trigger.new, trigger.oldMap);
    }
}