CREATE OR REPLACE FUNCTION LOG_OVART_remote(p_detailLevel in number default 0, p_part in varchar2, p_Event in varchar2,
    p_sessionid  in varchar2 default DBMS_SESSION.UNIQUE_SESSION_ID,
    p_sid        in number   default sys_context('UserEnv','SID'),
    p_spid       in number   default null,
    p_db_on_host in varchar2 default null, 
    p_job_id     in number   default null,
    p_job_chain   in varchar2 default null,
    p_author     in varchar2 default null,
    p_username in varchar2 default null
  ) return number
is
PRAGMA AUTONOMOUS_TRANSACTION;
  l_event       varchar2(15000);
  l_sessionid   varchar2(50)    := nvl(p_sessionid, DBMS_SESSION.UNIQUE_SESSION_ID);
  l_sid         number          := nvl(p_sid,       sys_context('UserEnv','SID'));
--  l_spid        pls_integer     := p_spid;
  l_part        varchar2(50)    := substr(p_part,1,50);
  l_info        tlog.client_info%type := sys_context('UserEnv','client_info');
--  writeRowCount number          := 0;
--  l_testlabel   pls_integer     := 0;
--  l_iid         number          := -1; -- код строки в таблице TLOG
  l_remote_iid  number          := -1; -- код строки в таблице TLOG на основном сервере

  l_db_on_host  VARCHAR2 (50)   := upper(nvl(p_db_on_host, sys_context('USERENV','DB_NAME')||' ('||sys_context('USERENV','DB_UNIQUE_NAME')||') on '||sys_context('USERENV','SERVER_HOST')));
  l_job_id      NUMBER          :=       nvl(p_job_id,     to_number(sys_context('jm_ctx','job_id')) );
  l_job_chain   varchar2(200)   := upper(nvl(p_job_chain,   sys_context('jm_ctx','job_chain')));
  l_author      varchar2(50)    := upper(coalesce(p_author,sys_context('jm_ctx','author'), sys_context('USERENV','OS_USER')));
  l_user        varchar2(50) := nvl(upper(p_username),user);
begin
/* execute immediate 'insert into depstat.tlog(iDebugLevel, part , cMsg,   sessionid,sid,spid, client_info,   DB_ON_HOST,JOB_ID,job_chain,AUTHOR )
          values(:detailLevel , :part, substr(l_Event, writeRowCount*100+1, 100), l_sessionid, l_sid,l_spid,l_info,  l_db_on_host,l_job_id,l_job_chain,l_author)'
          returning iid into l_remote_iid;*/

 execute immediate 'begin :res := log_ovart_f@tobis_dp(:detail, :part, :event, 
                :sessionid,:sid,:spid, :db_on_host, :job_id, :job_chain, :author, :username  ); end;' 
            using out l_remote_iid, in p_detailLevel, in l_part, in p_Event,   
                                    in l_sessionid, in l_sid, in p_spid, 
                                    in l_db_on_host, in l_job_id, in l_job_chain, in l_author, in l_user;
  commit;
  return l_remote_iid;
end;
/
