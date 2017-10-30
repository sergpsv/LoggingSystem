CREATE OR REPLACE FUNCTION LOG_OVART_F(p_detailLevel in number default 0, p_part in varchar2, p_Event in varchar2,
    p_sessionid  in varchar2 default DBMS_SESSION.UNIQUE_SESSION_ID,
    p_sid        in number   default sys_context('UserEnv','SID'),
    p_spid       in number   default null,
    p_db_on_host in varchar2 default null, 
    p_job_id     in number   default null,
    p_job_chain   in varchar2 default null,
    p_author     in varchar2 default null,
    p_username   in varchar2 default null
  ) return number
AUTHID CURRENT_USER
is
PRAGMA AUTONOMOUS_TRANSACTION;
  l_event       varchar2(15000);
  l_sessionid   varchar2(50)    := nvl(p_sessionid, DBMS_SESSION.UNIQUE_SESSION_ID);
  l_sid         number          := nvl(p_sid,       sys_context('UserEnv','SID'));
  l_spid        pls_integer     := p_spid;
  l_part        varchar2(50)    := substr(p_part,1,50);
  l_info        tlog.client_info%type := sys_context('UserEnv','client_info');
  writeRowCount number          := 0;
  l_testlabel   pls_integer     := 0;
  l_iid         number          := -1; -- код строки в таблице TLOG
  l_remote_iid  number          := -1; -- код строки в таблице TLOG на основном сервере

  l_db_on_host  VARCHAR2 (50)   := upper(nvl(p_db_on_host, sys_context('USERENV','DB_NAME')||' ('||sys_context('USERENV','DB_UNIQUE_NAME')||') on '||sys_context('USERENV','SERVER_HOST')));
  l_job_id      NUMBER          :=       nvl(p_job_id,     to_number(sys_context('jm_ctx','job_id')) );
  l_job_chain   varchar2(200)   := upper(nvl(p_job_chain,   sys_context('jm_ctx','job_chain')));
  l_author      varchar2(50)    := upper(coalesce(p_author,sys_context('jm_ctx','author'), sys_context('USERENV','OS_USER')));
  l_curruser    varchar2(50)    := user;
  l_user        varchar2(50)    := upper(nvl(p_username, l_curruser));
begin
    --------------- дл€ определени€ ID процесса ќ—
    begin
      if p_spid is null then 
        execute immediate 'select p.spid from v$mystat m, v$session s, v$process p 
                           where m.sid = s.sid and s.paddr = p.addr and rownum = 1' into l_spid;
      end if;
    exception
      when others then null;
    end;
    --------------- сбросить CLIENT_INFO если пуста€ строка
    if length(p_Event)=0 or p_Event is null then
      l_info := '';
    end if;
    --------------- форматируем с отступом по важности
    l_Event := LPAD(' ',p_detailLevel*2)||nvl(p_Event,' ');
    --------------- дл€ отладки в среде исполнени€
    if sys_context('UserEnv','SessionID') <> 0 then
      dbms_output.put_line(substr(p_event,1,255));
    end if;
    ---------------
    dbms_application_info.set_action(substr(p_event,1,32));
    while (length(l_Event)/100) > writeRowCount 
    loop
      insert into depstat.tlog(iDebugLevel, part , cMsg,   sessionid,sid,spid, client_info,   DB_ON_HOST,JOB_ID,job_chain,AUTHOR, username )
      values(p_detailLevel , l_part, substr(l_Event, writeRowCount*100+1, 100), l_sessionid, l_sid,l_spid,l_info,  l_db_on_host,l_job_id,l_job_chain,l_author, l_user)
      returning iid into l_iid;
      writeRowCount := writeRowCount +1;
    end loop;
    --------------- пишем на основной сервак со статистического
    begin
        select count(1) into l_testlabel from all_tables where owner='DEPSTAT' and table_name='TESTSERVER';
        if l_testlabel=1 then -- может не быть грантов на селект
          execute immediate 'begin :res := depstat.LOG_OVART_remote(:detail, :part, :event, 
                :sessionid,:sid,:spid, :db_on_host,:job_id,:job_chain,:author, :curr_user ); end;' 
            using out l_remote_iid, in p_detailLevel, in l_part, in p_Event,   
                                    in l_sessionid, in l_sid, in l_spid,   in l_db_on_host, in l_job_id, in l_job_chain, in l_author, in l_curruser;
        end if;
        if sys_context('jm_ctx','grab_log')='yes' then 
          l_event := 'begin j_manager.ctx_set(''grab_log'',''no''); j_manager.ctx_set(''grab_iid_'||to_char(l_iid)||','||to_char(l_remote_iid)||'); end;';
          dbms_output.put_line(l_event);
          execute immediate l_event;
        end if;
    exception
        when others then dbms_output.put_line(SQLERRM); -- нет ƒЅ линка
    end;

    commit;
    return l_iid;
exception 
  when others then
      l_event := dbms_utility.format_error_stack()||chr(13)||chr(10)||dbms_utility.format_error_backtrace();
      writeRowCount := 0;
      while (length(l_Event)/100) > writeRowCount 
      loop
          insert into depstat.tlog(iDebugLevel, part , cMsg,   sessionid,sid,spid, client_info,   DB_ON_HOST,JOB_ID,job_chain,AUTHOR, username  )
          values(p_detailLevel , l_part, substr(l_Event, writeRowCount*100+1, 100), l_sessionid, l_sid,l_spid,l_info,  l_db_on_host,l_job_id,l_job_chain,l_author, l_user)
          returning iid into l_iid;
          writeRowCount := writeRowCount +1;
      end loop;
      commit;
      return -1;
end;
/
