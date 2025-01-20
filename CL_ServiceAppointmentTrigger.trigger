trigger CL_ServiceAppointmentTrigger on ServiceAppointment (after insert, after update) {
    if (trigger.isInsert || trigger.isUndelete) {
        CL_ServiceAppointmentTriggerHandler.afterInsert(trigger.new);
    } else if (trigger.isUpdate) {
        CL_ServiceAppointmentTriggerHandler.afterUpdate(trigger.new, trigger.oldMap);
    }
}