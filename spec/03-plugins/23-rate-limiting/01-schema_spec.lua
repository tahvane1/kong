local helpers   = require "spec.helpers"
local schema_def = require "kong.plugins.rate-limiting.schema"
local v = require("spec.helpers").validate_plugin_config_schema


describe("Plugin: rate-limiting (schema)", function()
  it("proper config validates", function()
    local config = { second = 10 }
    local ok, _, err = v(config, schema_def)
    assert.truthy(ok)
    assert.is_nil(err)
  end)

  it("proper config validates (bis)", function()
    local config = { second = 10, minute = 20, hour = 30, day = 40, month = 50, year = 60 }
    local ok, _, err = v(config, schema_def)
    assert.truthy(ok)
    assert.is_nil(err)
  end)

  it("proper config validates (header)", function()
    local config = { second = 10, limit_by = "header", header_name = "X-App-Version" }
    local ok, _, err = v(config, schema_def)
    assert.truthy(ok)
    assert.is_nil(err)
  end)

  it("proper config validates (path)", function()
    local config = { second = 10, limit_by = "path", path = "/request" }
    local ok, _, err = v(config, schema_def)
    assert.truthy(ok)
    assert.is_nil(err)
  end)

  describe("errors", function()
    it("limits: smaller unit is less than bigger unit", function()
      local config = { second = 20, hour = 10 }
      local ok, err = v(config, schema_def)
      assert.falsy(ok)
      assert.equal("The limit for hour(10.0) cannot be lower than the limit for second(20.0)", err.config)
    end)

    it("limits: smaller unit is less than bigger unit (bis)", function()
      local config = { second = 10, minute = 20, hour = 30, day = 40, month = 60, year = 50 }
      local ok, err = v(config, schema_def)
      assert.falsy(ok)
      assert.equal("The limit for year(50.0) cannot be lower than the limit for month(60.0)", err.config)
    end)

    it("invalid limit", function()
      local config = {}
      local ok, err = v(config, schema_def)
      assert.falsy(ok)
      assert.same({"at least one of these fields must be non-empty: 'config.second', 'config.minute', 'config.hour', 'config.day', 'config.month', 'config.year'" },
                  err["@entity"])
    end)

    it("is limited by header but the header_name field is missing", function()
      local config = { second = 10, limit_by = "header", header_name = nil }
      local ok, err = v(config, schema_def)
      assert.falsy(ok)
      assert.equal("required field missing", err.config.header_name)
    end)

    it("is limited by path but the path field is missing", function()
      local config = { second = 10, limit_by = "path", path =  nil }
      local ok, err = v(config, schema_def)
      assert.falsy(ok)
      assert.equal("required field missing", err.config.path)
    end)

    it("is limited by path but the path field is missing", function()
      local config = { second = 10, limit_by = "path", path =  nil }
      local ok, err = v(config, schema_def)
      assert.falsy(ok)
      assert.equal("required field missing", err.config.path)
    end)

    it("proper config validates with redis new structure", function()
      local config = {
        second = 10,
        policy = "redis",
        redis = {
          host = helpers.redis_host,
          port = helpers.redis_port,
          database = 0,
          username = "test",
          password = "testXXX",
          ssl = true,
          ssl_verify = false,
          timeout = 1100,
          server_name = helpers.redis_ssl_sni,
      } }
      local ok, _, err = v(config, schema_def)
      assert.truthy(ok)
      assert.is_nil(err)
    end)

    it("proper config validates with redis legacy structure", function()
      local config = {
        second = 10,
        policy = "redis",
        redis_host = helpers.redis_host,
        redis_port = helpers.redis_port,
        redis_database = 0,
        redis_username = "test",
        redis_password = "testXXX",
        redis_ssl = true,
        redis_ssl_verify = false,
        redis_timeout = 1100,
        redis_server_name = helpers.redis_ssl_sni,
      }
      local ok, _, err = v(config, schema_def)
      assert.truthy(ok)
      assert.is_nil(err)
    end)

    it("verifies that redis required fields are supplied", function()
      local config = {
        second = 10,
        policy = "redis",
        redis = {
          port = helpers.redis_port,
          database = 0,
          username = "test",
          password = "testXXX",
          ssl = true,
          ssl_verify = false,
          timeout = 1100,
          server_name = helpers.redis_ssl_sni,
      } }
      local ok, err = v(config, schema_def)
      assert.falsy(ok)
      assert.contains("must set one of 'config.redis.host', 'config.redis_host' when 'policy' is 'redis'", err["@entity"])
    end)
  end)
end)
