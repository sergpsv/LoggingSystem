CREATE OR REPLACE PROCEDURE LOG_OVART_U( p_iid in number, up_event varchar2)
AUTHID CURRENT_USER
is
PRAGMA AUTONOMOUS_TRANSACTION;

  type TRefCursor is ref cursor;

  l_row     tlog%rowtype;
  rc        TRefCursor;
  l_exists  number := 0;
  l_stub    number;
  
  l_iid    number        :=0;
  l_part   varchar2(100) := 'row update';
  l_host   varchar2(100) := '';
  
  l_sessionid   varchar2(50)    := DBMS_SESSION.UNIQUE_SESSION_ID;
  l_sid         number          := sys_context('UserEnv','SID');
  l_spid        number          ;
  l_info        tlog.client_info%type ;
  l_db_on_host  VARCHAR2 (50)   := sys_context('USERENV','DB_NAME')||' ('||sys_context('USERENV','DB_UNIQUE_NAME')||') on '||sys_context('USERENV','SERVER_HOST');
  l_job_id      NUMBER          := to_number(sys_context('J_MANAGER_CTX','job_id')) ;
  l_job_chain    varchar2(200)   ;
  l_author      varchar2(50)    := upper(coalesce(sys_context('J_MANAGER_CTX','author'), sys_context('USERENV','OS_USER')));

begin
  open rc for select * from depstat.tlog where iid=p_iid;
    fetch rc into l_row;
    if rc%FOUND then 
      update depstat.tlog set cmsg=cmsg||substr(up_event,1,150-length(cmsg)) 
      where iid = p_iid returning iid into l_iid;
      l_sessionid := nvl(l_row.SESSIONID,  DBMS_SESSION.UNIQUE_SESSION_ID);
      l_sid       := nvl(l_row.sid,        sys_context('UserEnv','SID'));
      l_spid      := l_row.spid;
      l_info      := nvl(l_row.client_info, sys_context('UserEnv','client_info'));
      l_db_on_host:= upper(nvl(l_row.db_on_host, sys_context('USERENV','DB_NAME')||' ('||sys_context('USERENV','DB_UNIQUE_NAME')||') on '||sys_context('USERENV','SERVER_HOST')));
      l_job_id    :=       nvl(l_row.job_id,     to_number(sys_context('J_MANAGER_CTX','job_id')) );
      l_author    := upper(coalesce(l_row.author,sys_context('J_MANAGER_CTX','author'), sys_context('USERENV','OS_USER')));
    else
      execute immediate 'begin :l_stub := depstat.LOG_OVART_f(0, :l_part,:up_Event, :sessionID, :sid, :spid, 
               :db_on_host, :job_id, :job_chain, :author); end;'
                          using out l_stub , in l_part, in up_event, in l_sessionid, in l_sid, in l_spid,
                                    in l_db_on_host, in l_job_id, in l_job_chain, in l_author;
    end if;
  close rc;
     
  begin
    select count(*) into l_exists from user_tables where table_name='TESTSERVER';
    if l_exists=1 then 
      execute immediate 'declare r number; begin r:=log_ovart_f@tobis_dp(0, :part, :event, :sessionid ,  :sid,  :spid,
         :db_on_host, :job_id, :job_chain, :author); end;' 
        using l_part, up_Event, l_sessionid, l_sid, l_spid,  l_db_on_host,l_job_id,l_job_chain,l_author;
    end if;
  exception
    when others then
      dbms_output.put_line(SQLERRM);
  end;
      
  commit;
EXCEPTION
   WHEN others THEN
       null;
END;

/*PROCEDURE LOG_OVART_U( p_iid in number, up_event varchar2)
AUTHID CURRENT_USER  
is
  PRAGMA AUTONOMOUS_TRANSACTION;
  l_exists number;
  l_part   varchar2(100) := 'row update';
  l_host   varchar2(100) := '';
begin
   
  execute immediate 'update depstat.tlog set cmsg=cmsg||substr(:up_event,1,150-length(cmsg)) 
                       where iid = :p_iid ' using up_event, p_iid;
  if sql%rowcount=0 then 
    execute immediate 'begin depstat.log_ovart(p_part=>:l_part,p_event=>:up_event); end;' using l_part, up_event;
  end if;
      
  commit;
EXCEPTION
   WHEN others THEN
       null;
END;*/
/
