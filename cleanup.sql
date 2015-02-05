delete from s using site_def s left outer join drugtrial_def dt on dt.id=s.drugtrial_id where dt.id IS NULL;
delete from sa using site_address sa left outer join site_def s on s.id=sa.site_id where s.id IS NULL;
delete from subj using subject_def subj left outer join site_address sa on subj.location_id=sa.id where sa.id IS NULL;
delete from contact_address where address_id=0;
delete from a using activity a left outer join subject_def subj on subj.id=a.assoc_obj_id and a.assoc_obj='subject_def' where a.assoc_obj='subject_def' and subj.id IS NULL;
delete from sc, scp using subject_crf sc left outer join subject_crf_page scp on scp.subject_crf_id=sc.id left outer join subject_def subj on subj.id=sc.subject_id where subj.id IS NULL;
delete from a using activity a left outer join site_def site on site.id=a.assoc_obj_id and a.assoc_obj='site_def' where a.assoc_obj='site_def' and site.id IS NULL;
delete from a using activity a left outer join drugtrial_def dt on dt.id=a.assoc_obj_id and a.assoc_obj='drugtrial_def' where a.assoc_obj='drugtrial_def' and dt.id IS NULL;
delete from aadt using activity_detail_tmpl aadt left outer join activity_dfn ad on aadt.activity_dfn_id=ad.id where ad.id is null;
delete from aadt using assigned_activity_detail_tmpl aadt left outer join activity_dfn ad on aadt.activity_dfn_id=ad.id where ad.id is null;
update resource_def r left outer join resource_def r2 on r2.id=r.line_manager_id set r.line_manager_id=NULL where r2.id IS NULL;
update document_tmpl_assigned dta left outer join document_tmpl dt on dt.id=dta.document_tmpl_id set dta.document_tmpl_id=NULL where dt.id IS NULL;
update subject_deviations sd left outer join activity a on a.id=sd.activity_id set sd.activity_id=NULL where a.id IS NULL;
update site_company set type='1' where type='';
delete from sc using site_company sc left outer join site_def s on s.id=sc.site_id where s.id IS NULL;
delete from sc using site_contact sc left outer join contact_def c on c.id=sc.contact_id where c.id IS NULL;
delete from sc using site_contact sc left outer join site_def s on s.id=sc.site_id where s.id IS NULL;
delete from sit using site_int_team sit left outer join resource_def r on r.id=sit.resource_id where r.id IS NULL;
delete from sit using site_int_team sit left outer join site_def s on s.id=sit.site_id where s.id IS NULL;
delete from dit using drugtrial_int_team dit left outer join resource_def r on r.id=dit.resource_id where r.id IS NULL;
delete from dit using drugtrial_int_team dit left outer join drugtrial_def dt on dt.id=dit.drugtrial_id where dt.id IS NULL;
delete from  aes using activity_extended_status aes left outer join  activity a on a.id=aes.activity_id where a.id IS NULL;
delete from document_tmpl_assigned where assoc_obj='' or name='' or ASSIGNED_OBJ_ID ='';
delete from document_group_tmpl_assigned where assoc_obj='' or name='' or ASSIGNED_OBJ_ID ='';
update trigger_control set category='1' where category='';

update document_mgmt dm left outer join  document_tmpl_assigned dta on dta.id=dm.document_tmpl_assigned_id set document_tmpl_assigned_id=null where dm.document_tmpl_assigned_id IS NOT NULL and dta.id IS NULL;
delete from dm using document_mgmt dm left outer join drugtrial_def ao on ao.id=dm.assoc_obj_id and dm.assoc_obj='drugtrial_def' where ao.id IS NULL and dm.assoc_obj='drugtrial_def';
delete from dm using document_mgmt dm left outer join site_def ao on ao.id=dm.assoc_obj_id and dm.assoc_obj='site_def' where ao.id IS NULL and dm.assoc_obj='site_def';
delete from dm using document_mgmt dm left outer join dt_company ao on ao.id=dm.assoc_obj_id and dm.assoc_obj='dt_company' where ao.id IS NULL and dm.assoc_obj='dt_company';
delete from dm using document_mgmt dm left outer join site_company ao on ao.id=dm.assoc_obj_id and dm.assoc_obj='site_company' where ao.id IS NULL and dm.assoc_obj='site_company';
delete from dm using document_mgmt dm left outer join site_contact ao on ao.id=dm.assoc_obj_id and dm.assoc_obj='site_contact' where ao.id IS NULL and dm.assoc_obj='site_contact';
delete from dm using document_mgmt dm left outer join subject_def ao on ao.id=dm.assoc_obj_id and dm.assoc_obj='subject_def' where ao.id IS NULL and dm.assoc_obj='subject_def';
delete from dm using document_mgmt dm left outer join subject_deviations ao on ao.id=dm.assoc_obj_id and dm.assoc_obj='subject_deviations' where ao.id IS NULL and dm.assoc_obj='subject_deviations';
delete from dm using document_mgmt dm left outer join sae_subject ao on ao.id=dm.assoc_obj_id and dm.assoc_obj='sae_subject' where ao.id IS NULL and dm.assoc_obj='sae_subject';
delete from dm using document_mgmt dm left outer join contact_def ao on ao.id=dm.assoc_obj_id and dm.assoc_obj='contact_def' where ao.id IS NULL and dm.assoc_obj='contact_def';
delete from dm using document_mgmt dm left outer join company_def ao on ao.id=dm.assoc_obj_id and dm.assoc_obj='company_def' where ao.id IS NULL and dm.assoc_obj='company_def';

update resource_def r left outer join resource_def r2 on r2.id=r.LINE_MANAGER_ID set r.LINE_MANAGER_ID=null  where r2.id IS NULL;
update resource_def r left outer join company_def r2 on r2.id=r.COMPANY_ID set r.COMPANY_ID=null  where r2.id IS NULL;
update resource_def r left outer join department_def r2 on r2.id=r.DEPARTMENT_ID set r.DEPARTMENT_ID=null  where r2.id IS NULL;
update resource_def r left outer join division r2 on r2.id=r.DIVISION_ID set r.DIVISION_ID=null  where r2.id IS NULL;
update resource_def r left outer join contact_def r2 on r2.id=r.CONTACT_ID set r.CONTACT_ID=null  where r2.id IS NULL;

update project_def p left outer join company_def c on c.id=p.company_id set p.company_id=null  where c.id IS NULL;
update project_def p left outer join company_def c on c.id=p.customer_id set p.customer_id=null  where c.id IS NULL;
update project_def p left outer join contact_def c on c.id=p.PR_CUST_CONTACT_ID set p.PR_CUST_CONTACT_ID=null  where c.id IS NULL;
update project_def p left outer join resource_def r on r.id=p.MANAGER_ID set p.MANAGER_ID=null  where r.id IS NULL;
update project_def p left outer join project_def r on r.id=p.DEP_PROJ_ID set p.DEP_PROJ_ID=null  where r.id IS NULL;

delete from t using  task_def t left outer join project_def p on p.id=t.project_id where p.id IS NULL;
update task_def t left outer join task_def r on r.id=t.PARENT_ID set t.PARENT_ID=null  where r.id IS NULL;

update contact_def con left outer join company_def c on c.id=con.company_id set con.company_id=null  where c.id IS NULL;
update contact_def con left outer join contact_def c on c.id=con.BOSS_ID set con.BOSS_ID=null  where c.id IS NULL;

delete from wt using worktime_def wt left outer join task_def t ON t.id=wt.task_id where t.id IS NULL;
delete from wt using worktime_def wt left outer join resource_def r ON r.id=wt.resource_id where r.id IS NULL;
delete from e using expense_def e left outer join resource_def r ON r.id=e.resource_id where r.id IS NULL;
delete from e using expense_def e left outer join task_def t ON t.id=e.task_id where t.id IS NULL;

update team_tasks set  start_date=null where start_date='0000-00-00 00:00:00';
update team_member_tasks set  start_date=null where start_date='0000-00-00 00:00:00';
update team_members set  update_date=null where update_date='0000-00-00 00:00:00';
update requirements set CAPTURED_DATE=CREATE_DATE where CAPTURED_DATE='0000-00-00 00:00:00';
update requirements set ESTIMATED_DATE=null where ESTIMATED_DATE='0000-00-00 00:00:00';
update requirements set COMMIT_DATE=null where COMMIT_DATE='0000-00-00 00:00:00';
update requirements set SCHEDULED_DATE=null where SCHEDULED_DATE='0000-00-00 00:00:00';
update task_def set orig_start_date=null where orig_start_date='0000-00-00 00:00:00';
update task_def set orig_end_date=null where orig_end_date='0000-00-00 00:00:00';
update task_def set DEADLINE_DATE=null where DEADLINE_DATE='0000-00-00 00:00:00';
update test_case set update_date=null where update_date='0000-00-00 00:00:00';
update test_plan set update_date=null where update_date='0000-00-00 00:00:00';
update test set update_date=null where update_date='0000-00-00 00:00:00';
update resource_role set update_date=null where update_date='0000-00-00 00:00:00';
update news_tracker set news_date=null where news_date='0000-00-00 00:00:00';
update news_tracker set deadline_date=null where deadline_date='0000-00-00 00:00:00';
update news_tracker set end_date=null where end_date='0000-00-00 00:00:00';
delete from ra using report_acl ra left outer join role_acl racl on racl.id=ra.role_acl_id where racl.id is null;
update event_log set name=event_ref where name IS NULL or name='';
update attribute set tag=name where tag='' or tag IS NULL;
update attribute_tmpl set tag=name where tag='' or tag IS NULL;

delete from vr using visit_report vr left outer join questionnaire_group qg on qg.assoc_obj='visit_report' and qg.assoc_obj_id=vr.id where vr.assoc_obj='site_def' and qg.id is null;
delete from vr, rs using visit_report vr left outer join report_status rs on   vr.id=rs.assoc_obj_id and rs.assoc_obj='visit_report' left outer join site_def s on s.id=vr.assoc_obj_id and vr.assoc_obj='site_def' left outer join drugtrial_def dt on dt.id=s.drugtrial_id where s.id IS NULL or dt.id IS NULL;
delete from questionnaires where questionnaire_group_id NOT IN (select id from questionnaire_group);
delete from qg, qs, q, a using questionnaire_group qg left outer join visit_report vr on qg.assoc_obj='visit_report' and qg.assoc_obj_id=vr.id  left outer join questionnaires qs on qs.questionnaire_group_id=qg.id left outer join question q on q.questionnaires_id=qs.id left outer join answers a on a.question_id=q.id where qg.assoc_obj='visit_report' and vr.id IS NULL;
delete from q using question q left outer join questionnaires qs on qs.id=q.questionnaires_id where qs.id IS NULL;
delete from a using answers a left outer join question q on q.id=a.question_id where q.id IS NULL;
delete from a using activity a left outer join visit_report vr on a.assoc_obj='visit_report' and a.assoc_obj_id=vr.id where a.assoc_obj='visit_report'and vr.id IS NULL;
delete from rs using report_status rs left outer join visit_report vr on rs.assoc_obj='visit_report' and rs.assoc_obj_id=vr.id where rs.assoc_obj='visit_report'and vr.id IS NULL;
update module_service set name=service_alias where name='';
update activity set orig_tgt_date=null where orig_tgt_date='0000-00-00 00:00:00';
update activity set tgt_date=null where tgt_date='0000-00-00 00:00:00';

delete from q using quest_grp_detail_tmpl q left outer join quest_grp_tmpl qg on qg.id=q.quest_grp_tmpl_id left outer join questionnaires_tmpl qs on qs.id=q.questionnaires_tmpl_id where qg.id IS NULL or qs.id IS NULL;

update assigned_activity_detail_tmpl set orig_tgt_date=null where orig_tgt_date='0000-00-00 00:00:00';
update assigned_activity_detail_tmpl set tgt_date=null where tgt_date='0000-00-00 00:00:00';
update event_log set name=event_ref where name IS NULL or name='';
update news_tracker set news_date=null where news_date='0000-00-00 00:00:00';
update attribute set tag=name where tag='' or tag IS NULL;
update attribute_tmpl set tag=name where tag='' or tag IS NULL;


update dropdown_lookup set sub_tag=null where sub_tag='';
update dropdown_lookup set default_value='N' where default_value IS NULL;
update payment_cost_items set assoc_obj_id=id where assoc_obj_id!=id and assoc_obj='payment_cost_items';
update resource_def set birth_date=null where birth_date ='0000-00-00 00:00:00';
update resource_def set TERMINATION_date=null where TERMINATION_date ='0000-00-00 00:00:00';
update resource_def set hire_date=null where hire_date ='0000-00-00 00:00:00';
update subject_def set birth_date=null where birth_date ='0000-00-00 00:00:00';
update activity set done_date=null where done_date ='0000-00-00 00:00:00';
update activity_detail_tmpl set TGT_DATE=null where TGT_DATE='0000-00-00 00:00:00';
delete from  assigned_activity_detail_tmpl where ASSIGNED_ACTIVITY_TMPL_ID =0;
update report_status rs, visit_report vr, activity a set rs.SUBMISSION_DEADLINE=DATE_ADD(COALESCE(a.done_date,a.tgt_date,CURRENT_DATE), INTERVAL 14 DAY) where rs.SUBMISSION_DEADLINE='0000-00-00 00:00:00' and rs.assoc_obj='visit_report' and rs.assoc_obj_id=vr.id and vr.activity_id=a.id;
update drugtrial_milestone set forecast_date=COALESCE(ORIG_AGREED_DATE,CURRENT_DATE) where forecast_date='0000-00-00 00:00:00';
update orders set SHIPPED_CHECKED_DATE=null where SHIPPED_CHECKED_DATE='0000-00-00 00:00:00';
update orders set RCVD_CHECKED_DATE=null where RCVD_CHECKED_DATE='0000-00-00 00:00:00';
delete from subject_deviations where deviations_id=0;
delete from code_mapping where target='';
