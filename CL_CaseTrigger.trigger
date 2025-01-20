trigger CL_CaseTrigger on Case (after insert, after update) {
    if (trigger.isInsert || trigger.isUndelete) {
        CL_CaseTriggerHandler.afterInsert(trigger.new);
    } else if (trigger.isUpdate) {
        CL_CaseTriggerHandler.afterUpdate(trigger.new, trigger.oldMap);
    }
}