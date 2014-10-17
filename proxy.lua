--[[
  
  Copyright (C) 2014 Masatoshi Teruya
 
  proxy.lua
  lua-resty-proxy
  Created by Masatoshi Teruya on 14/10/17.
  
--]]
-- module
local encode = ngx.encode_args;
local encodeJSON = require('cjson.safe').encode;
local decodeJSON = require('cjson.safe').decode;
local HTTP_INTERNAL_SERVER_ERROR = ngx.HTTP_INTERNAL_SERVER_ERROR;
-- constants
local METHOD_IDS = {
    get         = ngx.HTTP_GET,
    head        = ngx.HTTP_HEAD,
    put         = ngx.HTTP_PUT,
    post        = ngx.HTTP_POST,
    delete      = ngx.HTTP_DELETE,
    options     = ngx.HTTP_OPTIONS,
    mkcol       = ngx.HTTP_MKCOL,
    copy        = ngx.HTTP_COPY,
    move        = ngx.HTTP_MOVE,
    propfind    = ngx.HTTP_PROPFIND,
    proppatch   = ngx.HTTP_PROPPATCH,
    lock        = ngx.HTTP_LOCK,
    unlock      = ngx.HTTP_UNLOCK,
    patch       = ngx.HTTP_PATCH,
    trace       = ngx.HTTP_TRACE
};

-- private
local function setHeaders( req, headers )
    if type( req.header ) == 'table' then
        for k, v in pairs( headers ) do
            req.header[k] = v;
        end
    else
        req.header = headers;
    end
end

--[[
    opts:
        body     = string or table
        bodyType = 'form' or 'json' (default: form)
        args     = table
        header   = table
--]]
local function invoke( method, uri, opts )
    local args, body, header, entity, err;
    
    if opts then
        -- invalid argument
        if type( opts ) ~= 'table' then
            return HTTP_INTERNAL_SERVER_ERROR, nil, 'opts must be table';
        elseif type( opts.body ) == 'table' then
            if not opts.bodyType or opts.bodyType == 'form' then
                body = encode( opts.body );
                setHeaders( opts, {
                    ['Content-Type'] = 'application/x-www-form-urlencoded',
                    ['Content-Length'] = #body
                });
            elseif opts.bodyType == 'json' then
                body, err = encodeJSON( opts.body );
                -- got encoding error
                if err then
                    return HTTP_INTERNAL_SERVER_ERROR, nil, err;
                end
                setHeaders( opts, {
                    ['Content-Type'] = 'application/json',
                    ['Content-Length'] = #body
                });
            -- invalid argument
            else
                return HTTP_INTERNAL_SERVER_ERROR, nil, 
                       'unsupported encoding type: ' .. opts.bodyType;
            end
        end
        
        args = opts.args;
        header = opts.header;
    end
    
    entity = ngx.location.capture( ngx.var.proxy_gateway, {
        method = method,
        args = args,
        body = body,
        ctx = {
            uri = uri,
            header = header
        }
    });
    
    -- decode json response
    if entity.header['Content-Type']:find( '^application/json' ) then
        entity.body, err = decodeJSON( entity.body );
    end
    
    return entity.status, entity, err;
end


-- class
local Proxy = require('halo').class.Proxy;

function Proxy.__index( _, method )
    method = METHOD_IDS[method];
    if method then
        return function( uri, opts )
            if type( uri ) ~= 'string' then
                return HTTP_INTERNAL_SERVER_ERROR, nil, 'uri must be string';
            end
            return invoke( method, uri, opts );
        end
    end
    
    return nil;
end


function Proxy.preflight()
    local req = ngx.ctx;
    
    ngx.req.set_uri( req.uri, false );
    if req.header then
        for k, v in pairs( req.header ) do
            ngx.req.set_header( k, v );
        end
    end
end


return Proxy.exports;
