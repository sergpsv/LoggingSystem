CREATE OR REPLACE PROCEDURE LOG_OVART(p_detailLevel in number default 0, p_part in varchar2, p_Event in varchar2,
    p_sessionid  in varchar2 default null,
    p_sid        in number   default null,
    p_spid       in number   default null,
    p_db_on_host in varchar2 default null, 
    p_job_id     in number   default null,
    p_job_chain   in varchar2 default null,
    p_author     in varchar2 default null
  )
AUTHID CURRENT_USER
is
PRAGMA AUTONOMOUS_TRANSACTION;
  l_remote_iid    number;
begin

  execute immediate 'begin :res := depstat.log_ovart_f(:detail, :part, :event, 
                :sessionid,:sid,:spid, :db_on_host,:job_id,:job_chain,:author  ); end;' 
            using out l_remote_iid, in p_detailLevel, in p_part, in p_Event,   
                                    in p_sessionid, in p_sid, in p_spid,   in p_db_on_host, in p_job_id, in p_job_chain, in p_author;    
  commit;
end;

/*PROCEDURE LOG_OVART(p_detailLevel in number default 0, p_part in varchar2, p_Event in varchar2, 
  p_db_link_name in varchar2 default null, 
  p_inst_host    in varchar2 default null)
AUTHID CURRENT_USER  
is
  PRAGMA AUTONOMOUS_TRANSACTION;
  l_stub    number;
begin
  execute immediate 'begin :stub := depstat.LOG_OVART_f(:detailLevel, :part, :event, :db_link_name, :inst_host); end;' 
              using out l_stub, in p_detailLevel , in p_part , in p_Event , in p_db_link_name , in p_inst_host;
  commit;
end;*/
/
