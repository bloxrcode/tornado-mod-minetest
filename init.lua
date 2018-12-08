--will warn the user that this mod is destructive
for i = 1,20 do
   print("!!!WARNING, THE TORNADO MOD WILL DESTROY YOUR MAP, REMOVE IF IN CREATIVE WORLD!!!")
end
minetest.after(3, function()
   for i = 1,20 do
      print("!!!WARNING, THE TORNADO MOD WILL DESTROY YOUR MAP, REMOVE IF IN CREATIVE WORLD!!!")
   end
end)


minetest.register_entity("tornado:t", { --basic minecart

   physical     = true,
   collisionbox = {-0.45, -0.45, -0.45, 0.45, 0.45, 0.45},
   visual       = "",
   --mesh         = "minecart.x",
   textures     = {""},
   visual_size = {x=1, y=1},
   stepheight = 2,
   automatic_face_movement_dir = 0,
   timer = 0,
   collide_with_objects = false,
   health = 1,
   timer_max = 0,
   vel_goal_x = 0,
   vel_goal_z = 0,


   --when the entity is created in world
   on_activate = function(self, staticdata, dtime_s)
      --self.object:set_armor_groups({immortal=1})
      --self.object:set_animation({x=45,y=45},0, 0)
      --self.object:setacceleration({x=0,y=0,z=0})
	
   end,
   get_staticdata = function(self)
      return minetest.serialize({
         timer = self.timer,
         used  = self.used,
         age   = self.age,
      })
   end,



   --what the mob does in the world
   on_step = function(self, dtime)
      self.timer = self.timer + dtime
      local pos = self.object:getpos()
      local vel = self.object:getvelocity()
      tornado_destruction(pos,self)
      if self.timer > self.timer_max then
         --change velocity goal
         --print("change velocity goal")
         self.timer = 0
         self.timer_max = math.random(2,4)
         --move
         self.vel_goal_x = math.random(-5,5)*math.random()
         self.vel_goal_z = math.random(-5,5)*math.random()
         
      end

      self.object:setacceleration({x=self.vel_goal_x - vel.x,y=0,z=self.vel_goal_z - vel.z})
   end,
   })

minetest.override_item("default:stick", {
   on_place = function(itemstack, placer, pointed_thing)
      minetest.add_entity(pointed_thing.above, "tornado:t")
   end,
})


--destroys blocks
function tornado_destruction(pos,self)
   if math.random() > 0.3 then
      return
   end
   local radius = 4
   local min = {x=pos.x-radius,y=pos.y-radius,z=pos.z-radius}
   local max = {x=pos.x+radius,y=pos.y+radius,z=pos.z+radius}
   local vm = minetest.get_voxel_manip()   
   local emin, emax = vm:read_from_map(min,max)
   local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
   local data = vm:get_data()
   
   local air = minetest.get_content_id("air")
   
   --minetest.get_name_from_content_id(content_id)
   
   for x = -radius,radius  do
      for z = -radius,radius  do
         for y = -radius,radius  do
            local p_pos = area:index(pos.x+x,pos.y+y,pos.z+z)
            local pos2 = {x=pos.x+x,y=pos.y+y,z=pos.z+z}
            if data[p_pos] == nil then
               return
            end
            local name = minetest.get_name_from_content_id(data[p_pos])
            local node = minetest.registered_items[name]
            if name ~= "air" then
               if math.random() > 0.96 then
                  data[p_pos] = minetest.get_content_id("air")
                  ent = spawn_tornado_ent(pos2, node)
                  ent:get_luaentity().goal = self.object
                  break
               end
            end
         end
      end
   end
   --vm:update_liquids()
   vm:set_data(data)
   vm:calc_lighting()
   vm:write_to_map()
   vm:update_map()
end



core.register_entity("tornado:t_ent", {
   initial_properties = {
      visual = "wielditem",
      visual_size = {x = 0.667, y = 0.667},
      textures = {},
      physical = false,
      is_visible = true,
      collide_with_objects = false,
      collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
      
   },
   health = 1,
   node = {},
   timer = 0,
   set_node = function(self, node)
      if node.name == "air" then
         self.object:remove()
      end
      self.node = node
      self.object:set_properties({
         is_visible = true,
         textures = {node.name},
      })
   end,

   get_staticdata = function(self)
      return core.serialize(self.node)
   end,

   on_activate = function(self, staticdata)
      self.object:set_armor_groups({immortal = 1})
      self.timer = 0
      
      local node = core.deserialize(staticdata)
      if node then
         self:set_node(node)
      elseif staticdata ~= "" then
         self:set_node({name = staticdata})
      end
   end,

   --what the mob does in the world
   on_step = function(self, dtime)
      self.timer = self.timer + dtime
      local pos = self.object:getpos()
      local vel = self.object:getvelocity()
      if self.goal ~= nil then
            if self.goal:get_luaentity() == nil then
               self.goal = nil
               return
            end
            local goalpos = self.goal:getpos()
            if pos.y - goalpos.y > 30 then
               self.object:remove()
            end
            --modified simplemobs api
            local vec = {x=pos.x-goalpos.x, y=pos.y-goalpos.y, z=pos.z-goalpos.z}
            
            local yaw = math.atan(vec.z/vec.x)+math.pi/2

            if pos.x > goalpos.x then
               yaw = yaw+math.pi
            end
            
            --self.object:setyaw(yaw)
             -- make a funnel
            local v = 30
            local x = 0
            local z = 0
            local radius = vec.y/10
            if math.abs(vec.x) < radius and math.abs(vec.z) < radius then
               x = math.sin(yaw) * -v 
               z = math.cos(yaw) * v
            else
               x = math.sin(yaw) * v 
               z = math.cos(yaw) * -v
            end
            
            self.object:setacceleration({x=x, y = 2,z=z})
      end


   end,
})

function spawn_tornado_ent(p, node)
   local obj = core.add_entity(p, "tornado:t_ent")
   obj:get_luaentity():set_node(node)
   return(obj)
end
