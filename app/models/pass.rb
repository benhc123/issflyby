class Pass < ActiveRecord::Base
	attr_accessible :risetime, :duration, :user_id, :spacecraft_id, :demo
	belongs_to :spacecraft
	belongs_to :user
  has_many :cards, dependent: :destroy

	before_save :sun_permits

	def weather_permits
		true
		#if self.user.lat && self.user.long
		#	# TODO check for cloudiness at the location and return false if it's cloudy
		#	return true
		#end
	end

	def sun_permits
    if self.demo
      true
    end

		if self.user.lat && self.user.long
			# Check to make sure the sun is positioned correctly and return false if not
        rise = Time.at(self.risetime)
        rise_date = Date.new(rise.year,rise.month,rise.day)
        sunrise = SunTimes.new.rise(rise_date, self.user.lat, self.user.long)
        sunrise_comparison = (sunrise.to_f - self.risetime.to_f)
        sunset = SunTimes.new.set(rise_date, self.user.lat, self.user.long)
        sunset_comparison = (self.risetime.to_f - sunset.to_f)
        unless (sunrise_comparison < 45.minutes && sunrise_comparison > 0) || (sunset_comparison < 45.minutes && sunset_comparison > 0)
          return false
        end
			return true
		else
			return false
		end
	end

	# iced because it doesn't work well with check_passes.rake
	# def passing_notify
	# 	if sun_permits && weather_permits
	# 		self.user.send_glass_card({text:self.spacecraft.name+" is passing over right now! "+pass.risetime.toString,isBundleCover:true})
	# 		# TODO delete advance_notify card
	# 	end
	# end	

	def advance_notify
		if weather_permits
			# TODO restructure for multiple space objects
				# self.user.send_glass_card({text:self.spacecraft.name+" is passing over soon! "+pass.risetime.toString,isBundleCover:true})
      self.spacecraft.spacepeople.each do |sp|
        if card = self.user.send_glass_card({text:sp.name+" is on board",isBundleCover:false},false)
          Card.create(pass_id:self.id,mirror_id:card['id'])
        end
      end
      local_risetime = self.risetime.in_time_zone(self.user.timezone)

      if card = self.user.send_glass_card({html:"<article>
  <figure>
    <img style=\"width:240px\" src=\"http://www.issflyby.com/assets/iss.jpg\">
  </figure>
  <section>
  #{self.spacecraft.name} flyby coming up #{local_risetime.strftime(" at %I:%M %p")}
  </section>
  <footer>ISS Flyby</footer>
</article>",isBundleCover:true})
        Card.create(pass_id:self.id,mirror_id:card['id'])
      end
		end
	end
end
#