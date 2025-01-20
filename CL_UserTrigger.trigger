trigger CL_UserTrigger on User (after insert, after update, after undelete) {

    if (trigger.isInsert || trigger.isUndelete) {
        CL_UserTriggerHandler.afterInsert(trigger.new);
    } else if (trigger.isUpdate) {
        CL_UserTriggerHandler.afterUpdate(trigger.new, trigger.oldMap);
    }
}