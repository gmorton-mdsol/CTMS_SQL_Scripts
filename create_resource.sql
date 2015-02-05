start transaction;

select @resource_id:=id from key_gen for update;

insert into resource_def(ID , USER_ID , LOGIN_ALLOWED , TYPE , PASSWORD_FORCE_CHANGE , CONTACT_ID , FIRST_NAME , MID_NAME , LAST_NAME , COMPANY_ID , DEPARTMENT_ID , LINE_MANAGER_ID , RESP_REGION , TITLE , QUALIFICATION , JOB_TITLE , SECURITY_LEVEL , SECURITY_ACCESS , EMPLOY_STATUS , FLEXI_TIME , HIRE_DATE , BIRTH_DATE , TIMESHEET_LOCK_DATE , EXPENSE_LOCK_DATE , TEL_NO , MOBILE_NO , FAX_NO , EMAIL , CURRENCY , INTERNAL_COST , BILL_RATE , HOLIDAY_ENTITLEMENT , PRODUCTIVE_HOURS , TERMINATION_DATE , DISTANCE_CURRENCY , DISTANCE_UNIT , DISTANCE_RATE , NOTES , LAST_UPDT_BY_ID , CREATED_BY_ID , ACTIVE , CREATE_DATE , USER_TIME_ZONE)
values(@resource_id , 'schow' , 'Y' , '1' , 'Y' , null , 'Sheila' , null , 'Chow' , null , null , null , null , null , null , null , 0 , 0 , 'FULL_TIME' , 'N' , null , null , null , null , null , null , null , 'schow@mdsol.com' , 'GBP' , null , null , null , null , null , 'Kms' , 'Kms' , null , null , 999 , 999 , 'Y' , CURRENT_TIMESTAMP , '300')

update key_gen set id=id+1;
select @rr_id:=id from key_gen for update;

insert into resource_change_tracking(ID , RESOURCE_ID , TERMINATION_DATE , CHANGED_BY_ID , LAST_UPDT_BY_ID , CREATED_BY_ID , ACTIVE , CREATE_DATE , USER_TIME_ZONE)
values(@rr_id , @resource_id , null , 999 , 999 , 999 , 'Y' , CURRENT_TIMESTAMP , '300');

update key_gen set id=id+1;
select @rr_id:=id from key_gen for update;
select @role_id:=id from role_def where name='Admin'

insert into resource_role(ID , ROLE_ID , RESOURCE_ID , DEFAULT_ROLE , DEFAULT_SRVC , LAST_UPDT_BY_ID , CREATED_BY_ID , ACTIVE , CREATE_DATE , USER_TIME_ZONE) 
values(@rr_id , @role_id , @resource_id , 'Y' , null , 999 , 999 , 'Y' , CURRENT_TIMESTAMP , '300');

update key_gen set id=id+1;

commit;