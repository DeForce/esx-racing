local default_table = [[
create table racing
(
    id    int auto_increment
        primary key,
    name varchar(50) not null,
    owner_id  varchar(50) not null
);
]]


MySQL.ready(function ()
    MySQL.Async.execute('SELECT 1 FROM racing LIMIT 1;', {}, function(ret)
        print(ret)
        if ret == nil then
            print("Table 'racing' doesn't exist. Running default Migration")
            RunDefaultMigration()
        end
    end)
end)

function RunDefaultMigration()
    MySQL.ready(function ()
        MySQL.Async.execute(default_table, {}, function(ret)
            print(ret)
        end)
    end)
end