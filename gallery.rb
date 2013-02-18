require 'haml'
require 'RMagick'
require 'json'
require 'yaml'
require 'exifr'

include Magick

=begin
Author: Taborelli, Eros <eros.taborelli@hurrdurr.com>, Jermini, Sylvain <sylvain.jermini@hurrdurr.com>
Version: 2.0
Date: 2010-09-17
Description: A minimalistic Photo Album with upload, descriptions and picture resize features.
License:
 Copyright (c) 2010-2013 hurrdurr.com

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.


Powered by:

- Sinatra 1.2.x (http://www.sinatrarb.com/)
- jQuery 1.3.2 (http://jquery.com/)
- jQuery Lightbox plugin (http://leandrovieira.com/projects/jquery/lightbox/)
- jQuery Multiple File Upload Plugin (http://www.fyneworks.com/jquery/multiple-file-upload/)

=end

begin
	content = File.new("configuration.yml").read
	CONFIG = YAML::load content
rescue Errno::ENOENT
	#config file
	if !File.exist?(Dir.pwd.concat("/configuration.yml")) then
		basicConfig = {'username' => 'admin', 'password' => 'admin', 'title' => 'Photo Album by hurrdurr.com' , 'navigation' => { 'Home' => '/' }, 'footer' => 'Photo Album by hurrdurr.com'}
		File.open(Dir.pwd.concat("/configuration.yml"), 'w' ) do |out|
			YAML.dump(basicConfig, out )
		end
	end
	content = File.new("configuration.yml").read
	CONFIG = YAML::load content
end

helpers do
	def galleryDir
		options.public + "/gallery"
	end
	
	def resizeDir
		options.public + "/resize"
	end
	
	def descriptionDir
		Dir.pwd + "/descriptions"
	end
	
	def encodedImages
		{ 	
			'bin.gif' => 'R0lGODlhEAAQAJEAAP///8zMzJmZmWZmZiH5BAEHAAAALAAAAAAQABAAAAJKhH8Bih0SVGQOsjjosWuLBnydEYkINCqCCa2ThZHXM5VfNIY1NHRTB+OFFj9AxnZ74Y4PQQ8nUTCFC5EKVeoZXIuB96tNOFEgQAEAOw==',
			'lightbox-blank.gif' => 'R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==',
			'lightbox-btn-close.gif' => 'R0lGODlhQgAWANUAAP////39/fr6+vj4+PX19fDw8Ovr6+np6ebm5uTk5N/f39zc3Nra2tfX19XV1dLS0svLy8jIyL6+vre3t7S0tLKysq+vr6ioqKOjo56enpubm5aWlpGRkY+Pj4yMjIeHh4KCgoCAgH19fXZ2dnNzc3FxcW5ubmlpaWdnZ2RkZGJiYl9fX11dXVpaWlVVVVNTU1BQUE5OTktLS0lJSUZGRgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAHAP8ALAAAAABCABYAAAb/QIBwSCwaj8ikcslsOp/QqLQZmFqvRAHngYxsBEaCw3EYHhwE5IFykZSLZ7RQPK4PBxzaimGEtGgcaXMZL4UvH0IXLw5HEoaFF0MEIo8RAA6PhUMWNC8xKw1EES0xLzQYQ5QfY2yJi0YRh2UKlBRCHC8XDhEZZZgcdYxCBiQzLzIqC0KjpTMhBUIULxlHisJEKCiCAAQoLEIvJEaYkUcGIzKeKAt+pTQgA0Pe20TWRQrTRYSMLyjjuUnOGYOBgtQxENsOHEJij4g0S6IA4gpEBJOICxjfEDmXDgaMYx/iDSHH8FU9kyMBTnrBguKlTNeIFCjx0ZMGMBUBVkPpKubL2XKXKLFQ8HNJgRM1Y3Qwgo9DSZ+ObBFxJKGIIxFFkywwUcrjMQ1ViLDwt9OnQkREcGkcQuJF1iMLUKSLkWLFRxlgTwK91NMIJaJC8GE14u1tkQUr0skgkSCCV7xhubUF5gCXJUUcMGJkpIAFCwkOKHgGnCHDmA/5LGoGyiCxCxkjDAiZ8DjvHEqFWFADoChTOQcoDKEADAC1od2YMglhwEIxCdlDKsjwSKMCnDFQFJAxEqdJgQ4yZjw3UiGGjBN8sKjP4mH8EQsnEKyfP0QAvSIB5NPfz7+/+iAAOw==',
			'lightbox-ico-loading.gif' => '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'
		}
	end
    
	def excludes
		[".", ".."]
	end
	
	def includes
		/(jpg)|(jpeg)|(png)|(gif)$/
	end
	
	def picturePerPage
		16
	end
	
	def checkPath(path)
		return File.expand_path(path).index(galleryDir) == 0 && File.exist?(path) && File.expand_path(path) == path
	end
	
	def createDirectories(dirList)
		(dirList.find_all {|dir| !File.directory?(dir)}).all? {|item| Dir.mkdir(item)}
	end
	
	def getSubDirectoriesByDirectory(dir)
		directoryList = []
		Dir.foreach(dir) do |entry|
			if !excludes.include?(entry) && File.directory?(dir + "/#{entry}") then
				directoryList.push(entry)
			end
		end
		return directoryList.sort
	end
	
	def getDirectoryContent(dir, filter)
		contentList = []
		Dir.entries(dir).each do |entry|
			if !excludes.include?(entry) && entry.downcase =~ filter then
				contentList.push(entry)
			end
		end
		return contentList.sort
	end
	
	def getFirstPictureInAlbum(album)
		pictureName = Dir.entries(galleryDir.concat("/#{album}")).sort[2]
	end
	
	def resizePicture(sourceImg, targetSize, imageAlbum, imageName)
		targetDirectory = resizeDir.concat("/#{targetSize}")
		thumbFolder = resizeDir.concat("/#{targetSize}/#{imageAlbum}")
		thumbImg = resizeDir.concat("/#{targetSize}/#{imageAlbum}/#{imageName}")
		
		#create the thumbnail if it's missing or if the source image has recently been updated
		if !File.exist?(thumbImg) || File.stat(sourceImg).mtime > File.stat(thumbImg).mtime then
			img = Image.read(sourceImg)
			imageSize = img[0].columns > img[0].rows ? img[0].columns : img[0].rows
			if targetSize > 1600 then
				thumb = img[0].columns > targetSize || img[0].rows > targetSize ? img[0].resize_to_fit(targetSize, targetSize) : img[0]
			else
				newWidth = img[0].columns >= img[0].rows ? targetSize : img[0].columns.to_f * (targetSize.to_f / img[0].rows.to_f)
				newHeight = img[0].rows >= img[0].columns ? targetSize : img[0].rows.to_f.to_f * (targetSize.to_f / img[0].columns.to_f)
				thumb = img[0].columns > targetSize || img[0].rows > targetSize ? img[0].resize(newWidth , newHeight, filter=BoxFilter) : img[0]
			end
			#check if directories exist
			createDirectories([resizeDir, targetDirectory, thumbFolder])

			thumb.write thumbImg
			img.all? {|item| item.destroy!}
			thumb.destroy!
		end
		return thumbImg
	end
	
	def paginate(album, currentPage, totalItems, action)
		totalPages = totalItems / picturePerPage + (totalItems % picturePerPage > 0 ? 1 : 0)
		paginateHTML = ''
		if totalPages > 1 then
			if currentPage > 1 then
				paginateHTML += '<a href="' + action + album + '/' + (currentPage - 1).to_s() + '">< prev </a>'
			end
			
			nums = ([ 1, 2, 3, currentPage - 1, currentPage, currentPage + 1, totalPages - 2, totalPages - 1, totalPages].find_all {|i|  i > 0 && i <= totalPages }).uniq.sort
			
			nums.each_index do |index|
				item = nums[index]
				paginateHTML += currentPage == item ? '<span class="currentPage">' + item.to_s() + '</span>' : '<a href="' + action + album + '/' + item.to_s() + '">' + item.to_s() + '</a>'
				
				if index + 1 < nums.length then
					paginateHTML += nums[index + 1] == item + 1 ? ', ' : ' ... '
				end
			end
			
			if currentPage < totalPages then
				paginateHTML += '<a href="' + action + album + '/' + (currentPage + 1).to_s() + '"> next ></a>'
			end
		end
		return paginateHTML
	end
	
	def getPreviewPicture(albumName, albumPreview)
		pictureName = albumPreview == nil || !File.exist?(galleryDir.concat("/#{albumName}/#{albumPreview}")) ? getFirstPictureInAlbum(albumName) : albumPreview
		return pictureName != nil ? "/resize/90/#{albumName}/#{pictureName}" : '/images/lightbox-blank.gif'
	end
	
	def getPicturesInAlbum(albumName)
		return (Dir.entries(galleryDir.concat("/").concat(albumName)).find_all {|i|  i.downcase =~ includes }).size
	end
	
	#EXIF
	def getExifData(imagePath)
		exifData = {}

		img = Image.read(imagePath)
		isJPEG = img[0].format == 'JPEG'

		exifData['Make'] = isJPEG && EXIFR::JPEG.new(imagePath).make != nil ? EXIFR::JPEG.new(imagePath).make : 'N/A'
		exifData['Model'] = isJPEG && EXIFR::JPEG.new(imagePath).model != nil ? EXIFR::JPEG.new(imagePath).model : 'N/A'
		exifData['Focal'] = isJPEG && EXIFR::JPEG.new(imagePath).focal_length != nil ? EXIFR::JPEG.new(imagePath).focal_length.to_s.concat('mm') : 'N/A'
		exifData['Exposure'] = isJPEG && EXIFR::JPEG.new(imagePath).exposure_time != nil ? EXIFR::JPEG.new(imagePath).exposure_time.to_s.concat('s') : 'N/A'
		exifData['Aperture'] = isJPEG && EXIFR::JPEG.new(imagePath).f_number != nil ? EXIFR::JPEG.new(imagePath).f_number.to_f.to_s.sub('.0','') : 'N/A'
		exifData['ISO'] = isJPEG && EXIFR::JPEG.new(imagePath).iso_speed_ratings != nil ? EXIFR::JPEG.new(imagePath).iso_speed_ratings.to_s : 'N/A'
		
		return exifData
	end
	
	#YAML FILE API
	def getAlbumsSettings
		return File.exist?(descriptionDir.concat("/albums.txt")) ? JSON.parse(File.new(descriptionDir.concat("/albums.txt")).read) : {}
	end
	
	def getPicturesDscriptionByAlbum(albumName)
		return File.exist?(descriptionDir.concat("/#{albumName}/pictures.txt")) ? JSON.parse(File.new(descriptionDir.concat("/#{albumName}/pictures.txt")).read) : {}
	end
	
	def writeAlbumsSettings(settings)
		createDirectories([descriptionDir])
		File.open(descriptionDir.concat("/albums.txt"), 'w' ) do |out|
			out.write settings.to_json
		end
	end
	
	def writePicturesDescriptionByAlbum(albumName, descriptions)
		createDirectories([descriptionDir, descriptionDir.concat("/#{albumName}")])
		File.open(descriptionDir.concat("/#{albumName}/pictures.txt"), 'w' ) do |out|
			out.write descriptions.to_json
		end
	end
	
	#HTTP BASIC AUTH
	def protected!
		response['WWW-Authenticate'] = %(Basic realm="Photo Album") and \
		throw(:halt, [401, "Not authorized\n"]) and \
		return unless authorized?
	end

	def authorized?
		@auth ||=  Rack::Auth::Basic::Request.new(request.env)
		@auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [CONFIG['username'], CONFIG['password']]
	end
		
end

before do
	if !File.directory?(galleryDir) then
		Dir.mkdir(galleryDir)
	end
end

not_found do
	@resources = []
	haml :error, :format => :html4
end

get '/' do
	@albumList = getSubDirectoriesByDirectory(galleryDir)
	
	#filter albums with 0 pictures
	@albumList = @albumList.find_all { |i| getPicturesInAlbum(i) > 0 }
	
	@albumNumbers = {}
	@albumModified = {}
	@albumDescription = {}
	@albumPreview = {}
	
	albumsData = getAlbumsSettings
	albumsData.keys.each do |item|
		@albumDescription[item] = albumsData[item]['description']
		
	end
	
	@albumList.each do |item|
		@albumModified[item] = File.stat(galleryDir.concat("/").concat(item)).mtime
		@albumNumbers[item] = getPicturesInAlbum(item)
		@albumPreview[item] = getPreviewPicture(item, (albumsData[item] != nil ? albumsData[item]['preview'] : nil))
	end
	
	@resources = []
	haml :index, :layout => :layoutlarge, :format => :html4
end

get '/album/:name/:page' do
	@pictureList = []
	
	#check it's an integer
	begin
		@pageNumber = Integer(params[:page])
	rescue
		halt 404, 'Not Found'
	end
	
	#check it's a correct path and the album exists
	albumPath = galleryDir.concat("/#{params[:name]}")
	if !checkPath(albumPath) then
		halt 404, 'Not Found'
	end
	
	@albumName = params[:name]
	@pictureList = getDirectoryContent(albumPath, includes)
	@paginate = paginate(@albumName, @pageNumber, @pictureList.length, '/album/')
	
	sliceStart = (@pageNumber-1)*picturePerPage
	#check it's in range
	if sliceStart > @pictureList.length then
		halt 404, 'Not Found'
	end
	@pictureList = @pictureList[sliceStart..(sliceStart+picturePerPage)-1]

	@resources = []
	haml :album, :layout => :layoutlarge, :format => :html4
end

#sinatra doesn't support default parameter values? :o
get '/album/:name' do
	redirect "/album/#{params[:name]}/1"
end

#normal image view
get '/view/:album/:image' do
	pictureList = []
	#check it's a correct path and the album exists
	albumPath = galleryDir.concat("/#{params[:album]}")
	imagePath = galleryDir.concat("/#{params[:album]}").concat("/#{params[:image]}")
	if !checkPath(imagePath) then
		halt 404, 'Not Found'
	end
	
	pictureList = getDirectoryContent(albumPath, includes)
	@albumName = params[:album]
	@currentPicture = params[:image]
	if @currentPicture != pictureList.first then
		@prevImage = pictureList[pictureList.index(@currentPicture) - 1]
	end
		
	if @currentPicture != pictureList.last then
		@nextImage = pictureList[pictureList.index(@currentPicture) + 1]
	end
		
	@currentImageNumber = pictureList.index(@currentPicture) + 1
	@totalImages = pictureList.length
		
	#get image size
	img = Image.read(imagePath)
	width = img[0].columns
	height = img[0].rows
	img.all? {|item| item.destroy!}
	@imageSize = width >= height ? width : height
	
	@backPage = (@currentImageNumber / picturePerPage + (@currentImageNumber % picturePerPage > 0 ? 1 : 0)).to_s()
	
	#picture description
	@pictureDescription = getPicturesDscriptionByAlbum(@albumName)[@currentPicture]
	
	#EXIF
	@exif = getExifData(imagePath)

	@resources = []
	haml :imageexif, :layout => :layoutexif, :format => :html4
end 

["/view/1024/:album/:image", "/view/1280/:album/:image", "/view/1600/:album/:image", "/view/original/:album/:image"].each do |path|
  get path do
	@imageView = request.path_info.sub("/#{params[:album]}/#{params[:image]}","").sub("/view/","")
	
	pictureList = []
	#check it's a correct path and the album exists
	albumPath = galleryDir.concat("/#{params[:album]}")
	imagePath = galleryDir.concat("/#{params[:album]}").concat("/#{params[:image]}")
	if !checkPath(imagePath) then
		halt 404, 'Not Found'
	end
	
	pictureList = getDirectoryContent(albumPath, includes)
	@albumName = params[:album]
	@currentPicture = params[:image]
		
	if @currentPicture != pictureList.first then
		@prevImage = pictureList[pictureList.index(@currentPicture) - 1]
	end
		
	if @currentPicture != pictureList.last then
		@nextImage = pictureList[pictureList.index(@currentPicture) + 1]
	end
		
	@currentImageNumber = pictureList.index(@currentPicture) + 1
	@totalImages = pictureList.length
		
	#get image size
	img = Image.read(imagePath)
	width = img[0].columns
	height = img[0].rows
	img.all? {|item| item.destroy!}
	@imageSize = width >= height ? width : height
	
	@backPage = (@currentImageNumber / picturePerPage + (@currentImageNumber % picturePerPage > 0 ? 1 : 0)).to_s()
	
	#preview URL
	if @imageSize < 1024 then
		@pictureURL = "/gallery/#{@albumName}/#{@currentPicture}"
	else
		@pictureURL = @imageView != 'original' ? "/resize/#{@imageView}/#{@albumName}/#{@currentPicture}" : "/gallery/#{@albumName}/#{@currentPicture}"
	end
	
	@resources = []
	haml :image, :layout => :layoutlarge, :format => :html4
  end
end

#get resize pictures
["/resize/90/:album/:image", "/resize/240/:album/:image", "/resize/645/:album/:image", "/resize/1024/:album/:image", "/resize/1280/:album/:image", "/resize/1600/:album/:image"].each do |path|
	get path do
		firstparam = request.path_info.sub("/#{params[:album]}/#{params[:image]}","").sub("/resize/","")
		sourceImg = galleryDir.concat("/#{params[:album]}/#{params[:image]}")
	
		#check it's a correct path and the image exists
		if !checkPath(sourceImg) then
			halt 404, 'Not Found'
		end
		
		thumbImg = resizePicture(sourceImg, firstparam.to_i(), params[:album], params[:image])
		#send right image type
		if params[:image].downcase =~ /jpg$/ then
			send_file thumbImg, :type => 'image/jpeg', :disposition => 'inline'
		elsif params[:image].downcase =~ /gif$/ then
			send_file thumbImg, :type => 'image/gif', :disposition => 'inline'
		else
			send_file thumbImg, :type => 'image/png', :disposition => 'inline'
		end
	end
end

get '/admin' do
	protected!
	@adminList = getSubDirectoriesByDirectory(galleryDir)
	
	@resources = []
	haml :admin, :layout => :adminlayout, :format => :html4
end

#returns album description, paginate infos, pictures list and pictures description as JSON object
get '/admin/album/:name/:page' do
	protected!
	
	#check it's an integer
	begin
		pageNumber = Integer(params[:page])
	rescue
		halt 404, 'Not Found'
	end
	
	#check it's a correct path and the album exists
	albumPath = galleryDir.concat("/#{params[:name]}")
	if !checkPath(albumPath) then
		halt 404, 'Not Found'
	end
	
	@albumName = params[:name]
	@pictureList = getDirectoryContent(albumPath, includes)
	@paginate = paginate(@albumName, pageNumber, @pictureList.length, '/admin/album/')
	
	sliceStart = (pageNumber-1)*picturePerPage
	#check it's in range
	if sliceStart > @pictureList.length then
		halt 404, 'Not Found'
	end
	
	@pictureList = @pictureList[sliceStart..(sliceStart+picturePerPage)-1]
	#album settings
	settings = getAlbumsSettings
	@albumDescription = settings[@albumName] != nil ? settings[@albumName]['description'] : nil
	@albumPreview = getPreviewPicture(@albumName, settings[@albumName] != nil ? settings[@albumName]['preview'] : nil)
	
	#pictures description
	@picturesDescription = getPicturesDscriptionByAlbum(@albumName)
	
	@adminList = getSubDirectoriesByDirectory(galleryDir)
	@resources = ['jquery.lightbox.js','admin.js']
	haml :adminalbum, :layout => :adminlayout, :format => :html4
end

#add album description
post '/admin/description/album/:name' do
	protected!
	#check album exists
	albumPath = galleryDir.concat("/#{params[:name]}")
	if checkPath(albumPath) then
		albumName = params[:name]
		comment = params['comment']
		comment = comment != nil && comment.length > 0 ? comment : nil
		
		#get albums settins
		settings = getAlbumsSettings
		
		#merge and save settings
		newsettings = settings[albumName] != nil ? { albumName => { 'description' => comment , 'preview' => settings[albumName]['preview'] }} : { albumName => { 'description' => comment }}
		settings = settings.merge(newsettings)
		writeAlbumsSettings(settings)
		
		#check comment
		returnJSON = comment != nil ? { 'hasMessage' => true, 'message' => Haml::Helpers.html_escape(comment) } : { 'hasMessage' => false }
	else
		returnJSON = { 'hasMessage' => false }
	end
	headers['Cache-Control'] = 'no-cache, must-revalidate'
	"#{returnJSON.to_json}"
end

#add album preview
post '/admin/preview/album/:name' do
	protected!
	headers['Cache-Control'] = 'no-cache, must-revalidate'
	#check album exists
	albumPath = galleryDir.concat("/#{params[:name]}")
	if checkPath(albumPath) then
		albumName = params[:name]
		preview = params['preview']
		
		#get albums settins
		settings = getAlbumsSettings
		
		#check preview
		if preview != nil && preview.length > 0 && File.exist?(galleryDir.concat("/#{params[:name]}/#{preview}")) then
			#merge and save settings
			newsettings = settings[albumName] != nil ? { albumName => { 'preview' => preview , 'description' => settings[albumName]['description'] }} : { albumName => { 'preview' => preview }}
			settings = settings.merge(newsettings)
			writeAlbumsSettings(settings)
			
			#return
			"#{staticURLBySize[90]}/#{params[:name]}/#{preview}"
		else
			"0"
		end
	else
		"0"
	end
end

#add image description
post '/admin/description/image/:album/:image' do
	protected!
	#check image exists
	imagePath = galleryDir.concat("/#{params[:album]}").concat("/#{params[:image]}")
	if checkPath(imagePath) then
		albumName = params[:album]
		pictureName = params[:image]
		comment = params['comment']
		comment = comment != nil && comment.length > 0 ? comment : nil
		
		#get pictures descriptions
		descriptions = getPicturesDscriptionByAlbum(albumName)
		
		#merge and save description
		newdescription = { pictureName => comment }
		descriptions = descriptions.merge(newdescription)
		writePicturesDescriptionByAlbum(albumName, descriptions)
		
		#check comment
		returnJSON = comment != nil ? { 'hasMessage' => true, 'message' => Haml::Helpers.html_escape(comment) } : { 'hasMessage' => false }
	else
		returnJSON = { 'hasMessage' => false }
	end
	headers['Cache-Control'] = 'no-cache, must-revalidate'
	"#{returnJSON.to_json}"
end

get '/admin/create' do
	@adminList = getSubDirectoriesByDirectory(galleryDir)
	@resources = []
	haml :admincreate, :layout => :adminlayout, :format => :html4
end

#create a new album directory
post '/admin/create' do
	protected!
	albumPath = galleryDir.concat("/#{params['name']}")
	if File.expand_path(albumPath).index(galleryDir) == 0 && !File.exist?(albumPath) then
		#create album
		createDirectories([galleryDir, albumPath])
		@status = { 'success' => true, 'message' => "Album #{Haml::Helpers.html_escape(params[:name])} created succesfully!" }
	else
		@status = { 'success' => false, 'message' => 'An error occurred while creating the new album.' }
	end
	@adminList = getSubDirectoriesByDirectory(galleryDir)
	@resources = []
	haml :adminstatus, :layout => :adminlayout, :format => :html4
end

#delete an album
post '/admin/delete' do
	protected!
	albumPath = galleryDir.concat("/#{params['name']}")
	if checkPath(albumPath) then
		#delete
		Dir.entries(albumPath).each do |entry|
			if !excludes.include?(entry) then
				File.unlink(galleryDir.concat("/#{params['name']}/#{entry}"))
			end
		end
		Dir.delete(albumPath)
		returnJSON = {'success' => true, 'message' => 'Album deleted succesfully!', 'album' => Haml::Helpers.html_escape(params['name']) }
	else
		returnJSON = {'success' => false, 'message' => 'An error occurred while deleteting the album.' }
	end
	headers['Cache-Control'] = 'no-cache, must-revalidate'
	"#{returnJSON.to_json}"
end

#delete pictures
post '/admin/deletepictures' do
	albumName = params[:name]
	albumPath = galleryDir.concat("/#{albumName}")
	if checkPath(albumPath) then
		pictureList = getDirectoryContent(albumPath, includes)
		(pictureList.find_all {|i| params[:deleteimages].include?(i)}).all? {|file| File.unlink(galleryDir.concat("/#{albumName}/#{file}")) }
		settings = getAlbumsSettings
		preview = getPreviewPicture(albumName, settings[albumName] != nil ? settings[albumName]['preview'] : nil)
		returnJSON = {'success' => true, 'message' => 'Pictures delete succesfully!', 'pictures' => params[:deleteimages], 'albumpreview' => preview }
	else
		returnJSON = {'success' => false, 'message' => 'Error while uploading pictures.' }
	end
	headers['Cache-Control'] = 'no-cache, must-revalidate'
	"#{returnJSON.to_json}"
end

get '/admin/upload' do
	@adminList = getSubDirectoriesByDirectory(galleryDir)
	@resources = ['upload.js','jquery.multiupload.js']
	haml :adminupload, :layout => :adminlayout, :format => :html4
end

#upload pictures in the correct album
post '/admin/upload' do
	protected!
	albumName = params[:album]
	albumPath = galleryDir.concat("/#{albumName}")
	if checkPath(albumPath) then
		params[:MyImages].each do |item|
			fromfile = item[:tempfile]
			tofile = galleryDir.concat("/#{albumName}").concat("/#{item[:filename]}")
			File.open(tofile.untaint, 'w') { |file| file << fromfile.read}
		end
		@status = {'success' => true, 'message' => 'Pictures uploaded succesfully!' }
	else
		@status = {'success' => false, 'message' => 'Error while uploading pictures.' }
	end
	@adminList = getSubDirectoriesByDirectory(galleryDir)
	@resources = []
	haml :adminstatus, :layout => :adminlayout, :format => :html4
end

get '/resources/css' do
	content_type 'text/css', :charset => 'utf-8'
	sass :stylesheet
end

get '/images/:name' do
	image = encodedImages[params[:name]]
	send_data Base64.decode64(image), :filename => params[:name], :type => 'image/gif', :disposition => 'inline' 
end

get '/resources/js/admin.js' do
	<<-JSADMIN
		$(document).ready(function() {
			//album info
			var currentAlbumName = $("#adminAlbumInfo h1").text();
			
			//add/edit
			$("#adminAlbumInfo p:first").click(function() {
				currentText = $("#adminAlbumInfo p:first").text();
				$("#adminAlbumInfo p textarea:first").val(currentText);
				$("#adminAlbumInfo p:first").css({'display':'none'});
				$("#adminAlbumInfo p:last").css({'display':'block'});
				$("#adminAlbumInfo div.buttonBar:first").css({'display':'block'});
			});
				
			//cancel
			$("#adminAlbumInfo div.buttonBar input[type='reset']:first").click(function() {
				$("#adminAlbumInfo p:first").css({'display':'block'});
				$("#adminAlbumInfo p:last").css({'display':'none'});
				$("#adminAlbumInfo div.buttonBar:first").css({'display':'none'});
			});
				
			//save
			$("#adminAlbumInfo div.buttonBar input[type='submit']:first").click(function() {
				currentText = $("#adminAlbumInfo p textarea:first").val();
				$.post("/admin/description/album/" + currentAlbumName, { comment: currentText },function(data){
					//parse JSON
					data = eval('(' + data + ')');
					if(data.hasMessage) {
						$("#adminAlbumInfo p:first").html(data.message);
					} else {
						$("#adminAlbumInfo p:first").html('<i>Click to add description</i>');
					}
					$("#adminAlbumInfo p:first").css({'display':'block'});
					$("#adminAlbumInfo p:last").css({'display':'none'});
					$("#adminAlbumInfo div.buttonBar:first").css({'display':'none'});
				});
			});
			
			//delete bars
			$("#topdeletebar input:first, #bottomdeletebar input:first").click(function() {
				$.post("/admin/delete", { name: currentAlbumName, }, function(data) {
					data = eval('(' + data + ')');
					if(data.success) {
						$("#content").html('<p class="statusSuccess">' + data.message + '</p>');
						//delete entry in list
						$("#adminalbumlist li a").each(function() {
							if($(this).text() == currentAlbumName) {
								$(this).fadeOut(500, function () {
									$(this).remove();
								});
							}
						});
					}
				});
			});
			
			$("#topdeletebar input:last, #bottomdeletebar input:last").click(function() {
				var images = []
				$("div.controlBar p input:checked").each(function() {
					hurr = $(this).parent("p").parent("div").parent("div").find("a img").attr("alt");
					images.push(hurr);
				});
				$.post("/admin/deletepictures", { name: currentAlbumName, 'deleteimages[]' : images }, function(data) {
					data = eval('(' + data + ')');
					if(data.success) {
						$("#adminImageList div.adminEntry").each(function() {
							if(jQuery.inArray($(this).find("a img").attr("alt"), data.pictures) != -1) {
								$(this).fadeOut(500, function () {
									$(this).remove();
								});
							}
						});
						$("#adminAlbumInfo img:first").attr("src",data.albumpreview);
						$("#adminAlbumInfo img:first").attr("alt",data.albumpreview);
					}
				});
			});
			
			//add pictures controls
			$("#adminImageList div.adminEntry").each(function() {
				var currentPictureName = $(this).find("a img").attr("alt");
				//set as album preview
				$(this).find("div.controlBar input[type='button']:first").click(function() {
					$.post("/admin/preview/album/" + currentAlbumName, { preview: currentPictureName },function(data) {
						if(data) {
							$("#adminAlbumInfo img:first").attr("src",data);
						}
					});
				});
				
				//add/edit
				$(this).find("div.descriptionBar p:first").click(function() {
					currentText = $(this).text();
					$(this).parent("div").find("p textarea:first").val(currentText);
					$(this).css({'display':'none'});
					$(this).parent("div").find("p:last").css({'display':'block'});
					$(this).parent("div").find("div.buttonBar:first").css({'display':'block'});
				});
				
				//cancel
				$(this).find("div.descriptionBar div.buttonBar input[type='reset']:first").click(function() {
					$(this).parent("div").parent("div").find("p:first").css({'display':'block'});
					$(this).parent("div").parent("div").find("p:last").css({'display':'none'});
					$(this).parent("div.buttonBar").css({'display':'none'});
				});
				
				//save
				$(this).find("div.descriptionBar div.buttonBar input[type='submit']:first").click(function() {
					var currentText = $(this).parent("div").parent("div").find("p textarea:first").val();
					var reference = this;
					$.post("/admin/description/image/" + currentAlbumName + "/" + currentPictureName, { comment: currentText },function(data){
						//parse JSON
						data = eval('(' + data + ')');
						if(data.hasMessage) {
							$(reference).parent("div").parent("div").find("p:first").html(data.message);
						} else {
							$(reference).parent("div").parent("div").find("p:first").html('<i>Click to add description</i>');
						}
						$(reference).parent("div").parent("div").find("p:first").css({'display':'block'});
						$(reference).parent("div").parent("div").find("p:last").css({'display':'none'});
						$(reference).parent("div.buttonBar").css({'display':'none'});
					});
				});
				
				//lightbox
				$(this).find("a").lightBox();
			});
		});
	JSADMIN
end

get '/resources/js/upload.js' do
	<<-JSUPLOAD
	$(document).ready(function() {
		$('#multiupload').MultiFile({ 
			STRING: {  
				remove: '<img src="/images/bin.gif" height="16" width="16" alt="x"/>'
			}
		});
				
		$('#resetQueue').click(function() {
			$('input:file').MultiFile('reset');
		});
		
		$('#uploadform').submit(function() {
			$("#status").html('<div align="center"><img src="/images/lightbox-ico-loading.gif"></div><div align="center">Uploading...</div>');
			return true;
		});
	});
	JSUPLOAD
end

get '/resources/js/jquery.lightbox.js' do
	data = 'LyoqDQogKiBqUXVlcnkgbGlnaHRCb3ggcGx1Z2luDQogKiBUaGlzIGpRdWVyeSBwbHVnaW4gd2FzIGluc3BpcmVkIGFuZCBiYXNlZCBvbiBMaWdodGJveCAyIGJ5IExva2VzaCBEaGFrYXIgKGh0dHA6Ly93d3cuaHVkZGxldG9nZXRoZXIuY29tL3Byb2plY3RzL2xpZ2h0Ym94Mi8pDQogKiBhbmQgYWRhcHRlZCB0byBtZSBmb3IgdXNlIGxpa2UgYSBwbHVnaW4gZnJvbSBqUXVlcnkuDQogKiBAbmFtZSBqcXVlcnktbGlnaHRib3gtMC41LmpzDQogKiBAYXV0aG9yIExlYW5kcm8gVmllaXJhIFBpbmhvIC0gaHR0cDovL2xlYW5kcm92aWVpcmEuY29tDQogKiBAdmVyc2lvbiAwLjUNCiAqIEBkYXRlIEFwcmlsIDExLCAyMDA4DQogKiBAY2F0ZWdvcnkgalF1ZXJ5IHBsdWdpbg0KICogQGNvcHlyaWdodCAoYykgMjAwOCBMZWFuZHJvIFZpZWlyYSBQaW5obyAobGVhbmRyb3ZpZWlyYS5jb20pDQogKiBAbGljZW5zZSBDQyBBdHRyaWJ1dGlvbi1ObyBEZXJpdmF0aXZlIFdvcmtzIDIuNSBCcmF6aWwgLSBodHRwOi8vY3JlYXRpdmVjb21tb25zLm9yZy9saWNlbnNlcy9ieS1uZC8yLjUvYnIvZGVlZC5lbl9VUw0KICogQGV4YW1wbGUgVmlzaXQgaHR0cDovL2xlYW5kcm92aWVpcmEuY29tL3Byb2plY3RzL2pxdWVyeS9saWdodGJveC8gZm9yIG1vcmUgaW5mb3JtYXRpb25zIGFib3V0IHRoaXMgalF1ZXJ5IHBsdWdpbg0KICovDQpldmFsKGZ1bmN0aW9uKHAsYSxjLGssZSxyKXtlPWZ1bmN0aW9uKGMpe3JldHVybihjPGE/Jyc6ZShwYXJzZUludChjL2EpKSkrKChjPWMlYSk+MzU/U3RyaW5nLmZyb21DaGFyQ29kZShjKzI5KTpjLnRvU3RyaW5nKDM2KSl9O2lmKCEnJy5yZXBsYWNlKC9eLyxTdHJpbmcpKXt3aGlsZShjLS0pcltlKGMpXT1rW2NdfHxlKGMpO2s9W2Z1bmN0aW9uKGUpe3JldHVybiByW2VdfV07ZT1mdW5jdGlvbigpe3JldHVybidcXHcrJ307Yz0xfTt3aGlsZShjLS0paWYoa1tjXSlwPXAucmVwbGFjZShuZXcgUmVnRXhwKCdcXGInK2UoYykrJ1xcYicsJ2cnKSxrW2NdKTtyZXR1cm4gcH0oJyg2KCQpeyQuMk4uM2c9Nig0KXs0PTIzLjJIKHsyQjpcJyMzNFwnLDJnOjAuOCwxZDpGLDFNOlwnMTgvNS0zMy1ZLjE2XCcsMXY6XCcxOC81LTF1LTJRLjE2XCcsMUU6XCcxOC81LTF1LTJMLjE2XCcsMVc6XCcxOC81LTF1LTJJLjE2XCcsMTk6XCcxOC81LTJGLjE2XCcsMWY6MTAsMkE6M2QsMnM6XCcxalwnLDJvOlwnMzJcJywyajpcJ2NcJywyZjpcJ3BcJywyZDpcJ25cJyxoOltdLDk6MH0sNCk7ZiBJPU47NiAyMCgpezFYKE4sSSk7dSBGfTYgMVgoMWUsSSl7JChcJzFVLCAxUywgMVJcJykubCh7XCcxUVwnOlwnMkVcJ30pOzFPKCk7NC5oLkI9MDs0Ljk9MDs3KEkuQj09MSl7NC5oLjFKKHYgMW0oMWUuMTcoXCdKXCcpLDFlLjE3KFwnMnZcJykpKX1qezM2KGYgaT0wO2k8SS5CO2krKyl7NC5oLjFKKHYgMW0oSVtpXS4xNyhcJ0pcJyksSVtpXS4xNyhcJzJ2XCcpKSl9fTJuKDQuaFs0LjldWzBdIT0xZS4xNyhcJ0pcJykpezQuOSsrfUQoKX02IDFPKCl7JChcJ21cJykuMzEoXCc8ZSBnPSJxLTEzIj48L2U+PGUgZz0icS01Ij48ZSBnPSI1LXMtYi13Ij48ZSBnPSI1LXMtYiI+PDF3IGc9IjUtYiI+PGUgMlY9IiIgZz0iNS1rIj48YSBKPSIjIiBnPSI1LWstViI+PC9hPjxhIEo9IiMiIGc9IjUtay1YIj48L2E+PC9lPjxlIGc9IjUtWSI+PGEgSj0iIyIgZz0iNS1ZLTI5Ij48MXcgVz0iXCcrNC4xTStcJyI+PC9hPjwvZT48L2U+PC9lPjxlIGc9IjUtcy1iLVQtdyI+PGUgZz0iNS1zLWItVCI+PGUgZz0iNS1iLUEiPjwxaSBnPSI1LWItQS0xdCI+PC8xaT48MWkgZz0iNS1iLUEtMWciPjwvMWk+PC9lPjxlIGc9IjUtMXMiPjxhIEo9IiMiIGc9IjUtMXMtMjIiPjwxdyBXPSJcJys0LjFXK1wnIj48L2E+PC9lPjwvZT48L2U+PC9lPlwnKTtmIHo9MUQoKTskKFwnI3EtMTNcJykubCh7Mks6NC4yQiwySjo0LjJnLFM6elswXSxQOnpbMV19KS4xVigpO2YgUj0xcCgpOyQoXCcjcS01XCcpLmwoezFUOlJbMV0rKHpbM10vMTApLDFjOlJbMF19KS5FKCk7JChcJyNxLTEzLCNxLTVcJykuQyg2KCl7MWEoKX0pOyQoXCcjNS1ZLTI5LCM1LTFzLTIyXCcpLkMoNigpezFhKCk7dSBGfSk7JChHKS4yRyg2KCl7ZiB6PTFEKCk7JChcJyNxLTEzXCcpLmwoe1M6elswXSxQOnpbMV19KTtmIFI9MXAoKTskKFwnI3EtNVwnKS5sKHsxVDpSWzFdKyh6WzNdLzEwKSwxYzpSWzBdfSl9KX02IEQoKXskKFwnIzUtWVwnKS5FKCk7Nyg0LjFkKXskKFwnIzUtYiwjNS1zLWItVC13LCM1LWItQS0xZ1wnKS4xYigpfWp7JChcJyM1LWIsIzUtaywjNS1rLVYsIzUtay1YLCM1LXMtYi1ULXcsIzUtYi1BLTFnXCcpLjFiKCl9ZiBRPXYgMWooKTtRLjFQPTYoKXskKFwnIzUtYlwnKS4yRChcJ1dcJyw0LmhbNC45XVswXSk7MU4oUS5TLFEuUCk7US4xUD02KCl7fX07US5XPTQuaFs0LjldWzBdfTs2IDFOKDFvLDFyKXtmIDFMPSQoXCcjNS1zLWItd1wnKS5TKCk7ZiAxSz0kKFwnIzUtcy1iLXdcJykuUCgpO2YgMW49KDFvKyg0LjFmKjIpKTtmIDF5PSgxcisoNC4xZioyKSk7ZiAxST0xTC0xbjtmIDJ6PTFLLTF5OyQoXCcjNS1zLWItd1wnKS4zZih7UzoxbixQOjF5fSw0LjJBLDYoKXsyeSgpfSk7NygoMUk9PTApJiYoMno9PTApKXs3KCQuM2UuM2MpezFIKDNiKX1qezFIKDNhKX19JChcJyM1LXMtYi1ULXdcJykubCh7Uzoxb30pOyQoXCcjNS1rLVYsIzUtay1YXCcpLmwoe1A6MXIrKDQuMWYqMil9KX07NiAyeSgpeyQoXCcjNS1ZXCcpLjFiKCk7JChcJyM1LWJcJykuMVYoNigpezJ1KCk7MnQoKX0pOzJyKCl9OzYgMnUoKXskKFwnIzUtcy1iLVQtd1wnKS4zOChcJzM1XCcpOyQoXCcjNS1iLUEtMXRcJykuMWIoKTs3KDQuaFs0LjldWzFdKXskKFwnIzUtYi1BLTF0XCcpLjJwKDQuaFs0LjldWzFdKS5FKCl9Nyg0LmguQj4xKXskKFwnIzUtYi1BLTFnXCcpLjJwKDQuMnMrXCcgXCcrKDQuOSsxKStcJyBcJys0LjJvK1wnIFwnKzQuaC5CKS5FKCl9fTYgMnQoKXskKFwnIzUta1wnKS5FKCk7JChcJyM1LWstViwjNS1rLVhcJykubCh7XCdLXCc6XCcxQyBNKFwnKzQuMTkrXCcpIEwtT1wnfSk7Nyg0LjkhPTApezcoNC4xZCl7JChcJyM1LWstVlwnKS5sKHtcJ0tcJzpcJ00oXCcrNC4xditcJykgMWMgMTUlIEwtT1wnfSkuMTEoKS4xayhcJ0NcJyw2KCl7NC45PTQuOS0xO0QoKTt1IEZ9KX1qeyQoXCcjNS1rLVZcJykuMTEoKS4ybSg2KCl7JChOKS5sKHtcJ0tcJzpcJ00oXCcrNC4xditcJykgMWMgMTUlIEwtT1wnfSl9LDYoKXskKE4pLmwoe1wnS1wnOlwnMUMgTShcJys0LjE5K1wnKSBMLU9cJ30pfSkuRSgpLjFrKFwnQ1wnLDYoKXs0Ljk9NC45LTE7RCgpO3UgRn0pfX03KDQuOSE9KDQuaC5CLTEpKXs3KDQuMWQpeyQoXCcjNS1rLVhcJykubCh7XCdLXCc6XCdNKFwnKzQuMUUrXCcpIDJsIDE1JSBMLU9cJ30pLjExKCkuMWsoXCdDXCcsNigpezQuOT00LjkrMTtEKCk7dSBGfSl9anskKFwnIzUtay1YXCcpLjExKCkuMm0oNigpeyQoTikubCh7XCdLXCc6XCdNKFwnKzQuMUUrXCcpIDJsIDE1JSBMLU9cJ30pfSw2KCl7JChOKS5sKHtcJ0tcJzpcJzFDIE0oXCcrNC4xOStcJykgTC1PXCd9KX0pLkUoKS4xayhcJ0NcJyw2KCl7NC45PTQuOSsxO0QoKTt1IEZ9KX19MmsoKX02IDJrKCl7JChkKS4zMCg2KDEyKXsyaSgxMil9KX02IDFHKCl7JChkKS4xMSgpfTYgMmkoMTIpezcoMTI9PTJoKXtVPTJaLjJlOzF4PTI3fWp7VT0xMi4yZTsxeD0xMi4yWX0xND0yWC4yVyhVKS4yVSgpOzcoKDE0PT00LjJqKXx8KDE0PT1cJ3hcJyl8fChVPT0xeCkpezFhKCl9NygoMTQ9PTQuMmYpfHwoVT09MzcpKXs3KDQuOSE9MCl7NC45PTQuOS0xO0QoKTsxRygpfX03KCgxND09NC4yZCl8fChVPT0zOSkpezcoNC45IT0oNC5oLkItMSkpezQuOT00LjkrMTtEKCk7MUcoKX19fTYgMnIoKXs3KCg0LmguQi0xKT40LjkpezJjPXYgMWooKTsyYy5XPTQuaFs0LjkrMV1bMF19Nyg0Ljk+MCl7MmI9diAxaigpOzJiLlc9NC5oWzQuOS0xXVswXX19NiAxYSgpeyQoXCcjcS01XCcpLjJhKCk7JChcJyNxLTEzXCcpLjJUKDYoKXskKFwnI3EtMTNcJykuMmEoKX0pOyQoXCcxVSwgMVMsIDFSXCcpLmwoe1wnMVFcJzpcJzJTXCd9KX02IDFEKCl7ZiBvLHI7NyhHLjFoJiZHLjI4KXtvPUcuMjYrRy4yUjtyPUcuMWgrRy4yOH1qIDcoZC5tLjI1PmQubS4yNCl7bz1kLm0uMlA7cj1kLm0uMjV9antvPWQubS4yTztyPWQubS4yNH1mIHksSDs3KFouMWgpezcoZC50LjFsKXt5PWQudC4xbH1qe3k9Wi4yNn1IPVouMWh9aiA3KGQudCYmZC50LjFBKXt5PWQudC4xbDtIPWQudC4xQX1qIDcoZC5tKXt5PWQubS4xbDtIPWQubS4xQX03KHI8SCl7MXo9SH1qezF6PXJ9NyhvPHkpezFCPW99ansxQj15fTIxPXYgMW0oMUIsMXoseSxIKTt1IDIxfTs2IDFwKCl7ZiBvLHI7NyhaLjFaKXtyPVouMVo7bz1aLjJNfWogNyhkLnQmJmQudC4xRil7cj1kLnQuMUY7bz1kLnQuMVl9aiA3KGQubSl7cj1kLm0uMUY7bz1kLm0uMVl9MnE9diAxbShvLHIpO3UgMnF9OzYgMUgoMkMpe2YgMng9diAydygpOzFxPTJoOzNoe2YgMXE9diAydygpfTJuKDFxLTJ4PDJDKX07dSBOLjExKFwnQ1wnKS5DKDIwKX19KSgyMyk7Jyw2MiwyMDQsJ3x8fHxzZXR0aW5nc3xsaWdodGJveHxmdW5jdGlvbnxpZnx8YWN0aXZlSW1hZ2V8fGltYWdlfHxkb2N1bWVudHxkaXZ8dmFyfGlkfGltYWdlQXJyYXl8fGVsc2V8bmF2fGNzc3xib2R5fHx4U2Nyb2xsfHxqcXVlcnl8eVNjcm9sbHxjb250YWluZXJ8ZG9jdW1lbnRFbGVtZW50fHJldHVybnxuZXd8Ym94fHx3aW5kb3dXaWR0aHxhcnJQYWdlU2l6ZXN8ZGV0YWlsc3xsZW5ndGh8Y2xpY2t8X3NldF9pbWFnZV90b192aWV3fHNob3d8ZmFsc2V8d2luZG93fHdpbmRvd0hlaWdodHxqUXVlcnlNYXRjaGVkT2JqfGhyZWZ8YmFja2dyb3VuZHxub3x1cmx8dGhpc3xyZXBlYXR8aGVpZ2h0fG9iakltYWdlUHJlbG9hZGVyfGFyclBhZ2VTY3JvbGx8d2lkdGh8ZGF0YXxrZXljb2RlfGJ0blByZXZ8c3JjfGJ0bk5leHR8bG9hZGluZ3xzZWxmfHx1bmJpbmR8b2JqRXZlbnR8b3ZlcmxheXxrZXl8fGdpZnxnZXRBdHRyaWJ1dGV8aW1hZ2VzfGltYWdlQmxhbmt8X2ZpbmlzaHxoaWRlfGxlZnR8Zml4ZWROYXZpZ2F0aW9ufG9iakNsaWNrZWR8Y29udGFpbmVyQm9yZGVyU2l6ZXxjdXJyZW50TnVtYmVyfGlubmVySGVpZ2h0fHNwYW58SW1hZ2V8YmluZHxjbGllbnRXaWR0aHxBcnJheXxpbnRXaWR0aHxpbnRJbWFnZVdpZHRofF9fX2dldFBhZ2VTY3JvbGx8Y3VyRGF0ZXxpbnRJbWFnZUhlaWdodHxzZWNOYXZ8Y2FwdGlvbnxidG58aW1hZ2VCdG5QcmV2fGltZ3xlc2NhcGVLZXl8aW50SGVpZ2h0fHBhZ2VIZWlnaHR8Y2xpZW50SGVpZ2h0fHBhZ2VXaWR0aHx0cmFuc3BhcmVudHxfX19nZXRQYWdlU2l6ZXxpbWFnZUJ0bk5leHR8c2Nyb2xsVG9wfF9kaXNhYmxlX2tleWJvYXJkX25hdmlnYXRpb258X19fcGF1c2V8aW50RGlmZld8cHVzaHxpbnRDdXJyZW50SGVpZ2h0fGludEN1cnJlbnRXaWR0aHxpbWFnZUxvYWRpbmd8X3Jlc2l6ZV9jb250YWluZXJfaW1hZ2VfYm94fF9zZXRfaW50ZXJmYWNlfG9ubG9hZHx2aXNpYmlsaXR5fHNlbGVjdHxvYmplY3R8dG9wfGVtYmVkfGZhZGVJbnxpbWFnZUJ0bkNsb3NlfF9zdGFydHxzY3JvbGxMZWZ0fHBhZ2VZT2Zmc2V0fF9pbml0aWFsaXplfGFycmF5UGFnZVNpemV8YnRuQ2xvc2V8alF1ZXJ5fG9mZnNldEhlaWdodHxzY3JvbGxIZWlnaHR8aW5uZXJXaWR0aHx8c2Nyb2xsTWF4WXxsaW5rfHJlbW92ZXxvYmpQcmV2fG9iak5leHR8a2V5VG9OZXh0fGtleUNvZGV8a2V5VG9QcmV2fG92ZXJsYXlPcGFjaXR5fG51bGx8X2tleWJvYXJkX2FjdGlvbnxrZXlUb0Nsb3NlfF9lbmFibGVfa2V5Ym9hcmRfbmF2aWdhdGlvbnxyaWdodHxob3Zlcnx3aGlsZXx0eHRPZnxodG1sfGFycmF5UGFnZVNjcm9sbHxfcHJlbG9hZF9uZWlnaGJvcl9pbWFnZXN8dHh0SW1hZ2V8X3NldF9uYXZpZ2F0aW9ufF9zaG93X2ltYWdlX2RhdGF8dGl0bGV8RGF0ZXxkYXRlfF9zaG93X2ltYWdlfGludERpZmZIfGNvbnRhaW5lclJlc2l6ZVNwZWVkfG92ZXJsYXlCZ0NvbG9yfG1zfGF0dHJ8aGlkZGVufGJsYW5rfHJlc2l6ZXxleHRlbmR8Y2xvc2V8b3BhY2l0eXxiYWNrZ3JvdW5kQ29sb3J8bmV4dHxwYWdlWE9mZnNldHxmbnxvZmZzZXRXaWR0aHxzY3JvbGxXaWR0aHxwcmV2fHNjcm9sbE1heFh8dmlzaWJsZXxmYWRlT3V0fHRvTG93ZXJDYXNlfHN0eWxlfGZyb21DaGFyQ29kZXxTdHJpbmd8RE9NX1ZLX0VTQ0FQRXxldmVudHxrZXlkb3dufGFwcGVuZHxvZnxpY298MDAwfGZhc3R8Zm9yfHxzbGlkZURvd258fDEwMHwyNTB8bXNpZXw0MDB8YnJvd3NlcnxhbmltYXRlfGxpZ2h0Qm94fGRvJy5zcGxpdCgnfCcpLDAse30pKQ=='
	send_data Base64.decode64(data), :filename => 'jquery.lightbox.js', :type => 'text/javascript', :disposition => 'inline'
end

get '/resources/js/jquery.multiupload.js' do
	data = 'LyoNCiAjIyMgalF1ZXJ5IE11bHRpcGxlIEZpbGUgVXBsb2FkIFBsdWdpbiB2MS40NiAtIDIwMDktMDUtMTIgIyMjDQogKiBIb21lOiBodHRwOi8vd3d3LmZ5bmV3b3Jrcy5jb20vanF1ZXJ5L211bHRpcGxlLWZpbGUtdXBsb2FkLw0KICogQ29kZTogaHR0cDovL2NvZGUuZ29vZ2xlLmNvbS9wL2pxdWVyeS1tdWx0aWZpbGUtcGx1Z2luLw0KICoNCiAqIER1YWwgbGljZW5zZWQgdW5kZXIgdGhlIE1JVCBhbmQgR1BMIGxpY2Vuc2VzOg0KICogICBodHRwOi8vd3d3Lm9wZW5zb3VyY2Uub3JnL2xpY2Vuc2VzL21pdC1saWNlbnNlLnBocA0KICogICBodHRwOi8vd3d3LmdudS5vcmcvbGljZW5zZXMvZ3BsLmh0bWwNCiAjIyMNCiovDQpldmFsKGZ1bmN0aW9uKHAsYSxjLGssZSxyKXtlPWZ1bmN0aW9uKGMpe3JldHVybihjPGE/Jyc6ZShwYXJzZUludChjL2EpKSkrKChjPWMlYSk+MzU/U3RyaW5nLmZyb21DaGFyQ29kZShjKzI5KTpjLnRvU3RyaW5nKDM2KSl9O2lmKCEnJy5yZXBsYWNlKC9eLyxTdHJpbmcpKXt3aGlsZShjLS0pcltlKGMpXT1rW2NdfHxlKGMpO2s9W2Z1bmN0aW9uKGUpe3JldHVybiByW2VdfV07ZT1mdW5jdGlvbigpe3JldHVybidcXHcrJ307Yz0xfTt3aGlsZShjLS0paWYoa1tjXSlwPXAucmVwbGFjZShuZXcgUmVnRXhwKCdcXGInK2UoYykrJ1xcYicsJ2cnKSxrW2NdKTtyZXR1cm4gcH0oJzszKFUuMXUpKDYoJCl7JC43LjI9NihoKXszKDUuVj09MCk4IDU7MyhUIFNbMF09PVwnMTlcJyl7Myg1LlY+MSl7bSBpPVM7OCA1Lk0oNigpeyQuNy4yLjEzKCQoNSksaSl9KX07JC43LjJbU1swXV0uMTMoNSwkLjFOKFMpLjI3KDEpfHxbXSk7OCA1fTttIGg9JC5OKHt9LCQuNy4yLkYsaHx8e30pOyQoXCcyZFwnKS4xQihcJzItUlwnKS5RKFwnMi1SXCcpLjFuKCQuNy4yLlopOzMoJC43LjIuRi4xNSl7JC43LjIuMU0oJC43LjIuRi4xNSk7JC43LjIuRi4xNT0xMH07NS4xQihcJy4yLTFlXCcpLlEoXCcyLTFlXCcpLk0oNigpe1UuMj0oVS4yfHwwKSsxO20gZT1VLjI7bSBnPXtlOjUsRTokKDUpLEw6JCg1KS5MKCl9OzMoVCBoPT1cJzIxXCcpaD17bDpofTttIG89JC5OKHt9LCQuNy4yLkYsaHx8e30sKCQuMW0/Zy5FLjFtKCk6KCQuMVM/Zy5FLjE3KCk6MTApKXx8e30se30pOzMoIShvLmw+MCkpe28ubD1nLkUuRChcJzI4XCcpOzMoIShvLmw+MCkpe28ubD0odShnLmUuMUQuQigvXFxiKGx8MjMpXFwtKFswLTldKylcXGIvcSl8fFtcJ1wnXSkuQigvWzAtOV0rL3EpfHxbXCdcJ10pWzBdOzMoIShvLmw+MCkpby5sPS0xOzJiIG8ubD11KG8ubCkuQigvWzAtOV0rL3EpWzBdfX07by5sPTE4IDJmKG8ubCk7by5qPW8uanx8Zy5FLkQoXCdqXCcpfHxcJ1wnOzMoIW8uail7by5qPShnLmUuMUQuQigvXFxiKGpcXC1bXFx3XFx8XSspXFxiL3EpKXx8XCdcJztvLmo9MTggdShvLmopLnQoL14oanwxZClcXC0vaSxcJ1wnKX07JC5OKGcsb3x8e30pO2cuQT0kLk4oe30sJC43LjIuRi5BLGcuQSk7JC5OKGcse246MCxKOltdLDJjOltdLDFjOmcuZS5JfHxcJzJcJyt1KGUpLDFpOjYoeil7OCBnLjFjKyh6PjA/XCcxWlwnK3Uoeik6XCdcJyl9LEc6NihhLGIpe20gYz1nW2FdLGs9JChiKS5EKFwna1wnKTszKGMpe20gZD1jKGIsayxnKTszKGQhPTEwKTggZH04IDFhfX0pOzModShnLmopLlY+MSl7Zy5qPWcuai50KC9cXFcrL2csXCd8XCcpLnQoL15cXFd8XFxXJC9nLFwnXCcpO2cuMWs9MTggMnQoXCdcXFxcLihcJysoZy5qP2cuajpcJ1wnKStcJykkXCcsXCdxXCcpfTtnLk89Zy4xYytcJzFQXCc7Zy5FLjFsKFwnPFAgWD0iMi0xbCIgST0iXCcrZy5PK1wnIj48L1A+XCcpO2cuMXE9JChcJyNcJytnLk8rXCdcJyk7Zy5lLkg9Zy5lLkh8fFwncFwnK2UrXCdbXVwnOzMoIWcuSyl7Zy4xcS4xZyhcJzxQIFg9IjItSyIgST0iXCcrZy5PK1wnMUYiPjwvUD5cJyk7Zy5LPSQoXCcjXCcrZy5PK1wnMUZcJyl9O2cuSz0kKGcuSyk7Zy4xNj02KGMsZCl7Zy5uKys7Yy4yPWc7MyhkPjApYy5JPWMuSD1cJ1wnOzMoZD4wKWMuST1nLjFpKGQpO2MuSD11KGcuMWoudCgvXFwkSC9xLCQoZy5MKS5EKFwnSFwnKSkudCgvXFwkSS9xLCQoZy5MKS5EKFwnSVwnKSkudCgvXFwkZy9xLGUpLnQoL1xcJGkvcSxkKSk7MygoZy5sPjApJiYoKGcubi0xKT4oZy5sKSkpYy4xND0xYTtnLlk9Zy5KW2RdPWM7Yz0kKGMpO2MuMWIoXCdcJykuRChcJ2tcJyxcJ1wnKVswXS5rPVwnXCc7Yy5RKFwnMi0xZVwnKTtjLjFWKDYoKXskKDUpLjFYKCk7MyghZy5HKFwnMVlcJyw1LGcpKTggeTttIGE9XCdcJyx2PXUoNS5rfHxcJ1wnKTszKGcuaiYmdiYmIXYuQihnLjFrKSlhPWcuQS4xby50KFwnJDFkXCcsdSh2LkIoL1xcLlxcd3sxLDR9JC9xKSkpOzFwKG0gZiAyYSBnLkopMyhnLkpbZl0mJmcuSltmXSE9NSkzKGcuSltmXS5rPT12KWE9Zy5BLjFyLnQoXCckcFwnLHYuQigvW15cXC9cXFxcXSskL3EpKTttIGI9JChnLkwpLkwoKTtiLlEoXCcyXCcpOzMoYSE9XCdcJyl7Zy4xcyhhKTtnLm4tLTtnLjE2KGJbMF0sZCk7Yy4xdCgpLjJlKGIpO2MuQygpOzggeX07JCg1KS4xdih7MXc6XCcxT1wnLDF4OlwnLTFRXCd9KTtjLjFSKGIpO2cuMXkoNSxkKTtnLjE2KGJbMF0sZCsxKTszKCFnLkcoXCcxVFwnLDUsZykpOCB5fSk7JChjKS4xNyhcJzJcJyxnKX07Zy4xeT02KGMsZCl7MyghZy5HKFwnMVVcJyxjLGcpKTggeTttIHI9JChcJzxQIFg9IjItMVciPjwvUD5cJyksdj11KGMua3x8XCdcJyksYT0kKFwnPDF6IFg9IjItMUEiIDFBPSJcJytnLkEuMTIudChcJyRwXCcsdikrXCciPlwnK2cuQS5wLnQoXCckcFwnLHYuQigvW15cXC9cXFxcXSskL3EpWzBdKStcJzwvMXo+XCcpLGI9JChcJzxhIFg9IjItQyIgMnk9IiNcJytnLk8rXCciPlwnK2cuQS5DK1wnPC9hPlwnKTtnLksuMWcoci4xZyhiLFwnIFwnLGEpKTtiLjFDKDYoKXszKCFnLkcoXCcyMlwnLGMsZykpOCB5O2cubi0tO2cuWS4xND15O2cuSltkXT0xMDskKGMpLkMoKTskKDUpLjF0KCkuQygpOyQoZy5ZKS4xdih7MXc6XCdcJywxeDpcJ1wnfSk7JChnLlkpLjExKCkuMWIoXCdcJykuRChcJ2tcJyxcJ1wnKVswXS5rPVwnXCc7MyghZy5HKFwnMjRcJyxjLGcpKTggeTs4IHl9KTszKCFnLkcoXCcyNVwnLGMsZykpOCB5fTszKCFnLjIpZy4xNihnLmUsMCk7Zy5uKys7Zy5FLjE3KFwnMlwnLGcpfSl9OyQuTigkLjcuMix7MTE6Nigpe20gYT0kKDUpLjE3KFwnMlwnKTszKGEpYS5LLjI2KFwnYS4yLUNcJykuMUMoKTs4ICQoNSl9LFo6NihhKXthPShUKGEpPT1cJzE5XCc/YTpcJ1wnKXx8XCcxRVwnO20gbz1bXTskKFwnMWg6cC4yXCcpLk0oNigpezMoJCg1KS4xYigpPT1cJ1wnKW9bby5WXT01fSk7OCAkKG8pLk0oNigpezUuMTQ9MWF9KS5RKGEpfSwxZjo2KGEpe2E9KFQoYSk9PVwnMTlcJz9hOlwnXCcpfHxcJzFFXCc7OCAkKFwnMWg6cC5cJythKS4yOShhKS5NKDYoKXs1LjE0PXl9KX0sUjp7fSwxTTo2KGIsYyxkKXttIGUsaztkPWR8fFtdOzMoZC4xRy4xSCgpLjFJKCIxSiIpPDApZD1bZF07MyhUKGIpPT1cJzZcJyl7JC43LjIuWigpO2s9Yi4xMyhjfHxVLGQpOzFLKDYoKXskLjcuMi4xZigpfSwxTCk7OCBrfTszKGIuMUcuMUgoKS4xSSgiMUoiKTwwKWI9W2JdOzFwKG0gaT0wO2k8Yi5WO2krKyl7ZT1iW2ldK1wnXCc7MyhlKSg2KGEpeyQuNy4yLlJbYV09JC43W2FdfHw2KCl7fTskLjdbYV09NigpeyQuNy4yLlooKTtrPSQuNy4yLlJbYV0uMTMoNSxTKTsxSyg2KCl7JC43LjIuMWYoKX0sMUwpOzgga319KShlKX19fSk7JC43LjIuRj17ajpcJ1wnLGw6LTEsMWo6XCckSFwnLEE6e0M6XCd4XCcsMW86XCcyZyAyaCAyaSBhICQxZCBwLlxcMmogMmsuLi5cJyxwOlwnJHBcJywxMjpcJzJsIDEyOiAkcFwnLDFyOlwnMm0gcCAybiAybyAycCAxMjpcXG4kcFwnfSwxNTpbXCcxblwnLFwnMnFcJyxcJzJyXCcsXCcyc1wnXSwxczo2KHMpezJ1KHMpfX07JC43LjExPTYoKXs4IDUuTSg2KCl7MnZ7NS4xMSgpfTJ3KGUpe319KX07JCg2KCl7JCgiMWhbMng9cF0uMjAiKS4yKCl9KX0pKDF1KTsnLDYyLDE1OSwnfHxNdWx0aUZpbGV8aWZ8fHRoaXN8ZnVuY3Rpb258Zm58cmV0dXJufHx8fHx8fHx8fHxhY2NlcHR8dmFsdWV8bWF4fHZhcnx8fGZpbGV8Z2l8fHxyZXBsYWNlfFN0cmluZ3x8fHxmYWxzZXx8U1RSSU5HfG1hdGNofHJlbW92ZXxhdHRyfHxvcHRpb25zfHRyaWdnZXJ8bmFtZXxpZHxzbGF2ZXN8bGlzdHxjbG9uZXxlYWNofGV4dGVuZHx3cmFwSUR8ZGl2fGFkZENsYXNzfGludGVyY2VwdGVkfGFyZ3VtZW50c3x0eXBlb2Z8d2luZG93fGxlbmd0aHx8Y2xhc3N8Y3VycmVudHxkaXNhYmxlRW1wdHl8bnVsbHxyZXNldHxzZWxlY3RlZHxhcHBseXxkaXNhYmxlZHxhdXRvSW50ZXJjZXB0fGFkZFNsYXZlfGRhdGF8bmV3fHN0cmluZ3x0cnVlfHZhbHxpbnN0YW5jZUtleXxleHR8YXBwbGllZHxyZUVuYWJsZUVtcHR5fGFwcGVuZHxpbnB1dHxnZW5lcmF0ZUlEfG5hbWVQYXR0ZXJufHJ4QWNjZXB0fHdyYXB8bWV0YWRhdGF8c3VibWl0fGRlbmllZHxmb3J8d3JhcHBlcnxkdXBsaWNhdGV8ZXJyb3J8cGFyZW50fGpRdWVyeXxjc3N8cG9zaXRpb258dG9wfGFkZFRvTGlzdHxzcGFufHRpdGxlfG5vdHxjbGlja3xjbGFzc05hbWV8bWZEfF9saXN0fGNvbnN0cnVjdG9yfHRvU3RyaW5nfGluZGV4T2Z8QXJyYXl8c2V0VGltZW91dHwxMDAwfGludGVyY2VwdHxtYWtlQXJyYXl8YWJzb2x1dGV8X3dyYXB8MzAwMHB4fGFmdGVyfG1ldGF8YWZ0ZXJGaWxlU2VsZWN0fG9uRmlsZUFwcGVuZHxjaGFuZ2V8bGFiZWx8Ymx1cnxvbkZpbGVTZWxlY3R8X0Z8bXVsdGl8bnVtYmVyfG9uRmlsZVJlbW92ZXxsaW1pdHxhZnRlckZpbGVSZW1vdmV8YWZ0ZXJGaWxlQXBwZW5kfGZpbmR8c2xpY2V8bWF4bGVuZ3RofHJlbW92ZUNsYXNzfGlufGVsc2V8ZmlsZXN8Zm9ybXxwcmVwZW5kfE51bWJlcnxZb3V8Y2Fubm90fHNlbGVjdHxuVHJ5fGFnYWlufEZpbGV8VGhpc3xoYXN8YWxyZWFkeXxiZWVufGFqYXhTdWJtaXR8YWpheEZvcm18dmFsaWRhdGV8UmVnRXhwfGFsZXJ0fHRyeXxjYXRjaHx0eXBlfGhyZWYnLnNwbGl0KCd8JyksMCx7fSkp'
	send_data Base64.decode64(data), :filename => 'jquery.multiupload.js', :type => 'text/javascript', :disposition => 'inline'
end


__END__

@@ stylesheet
@charset "UTF-8"

body, html
  font-family: "Trebuchet MS", Helvetica, Tahoma, Verdana, Arial
  font-size: 11px
  margin: 0
  padding: 0
  border: 0
  height: 100%


img
  border: 0px


a
  color: #3466a4
  text-decoration: none

  &:hover
    text-decoration: underline

h1
  clear: both
  color: #3466a4

table
  tr
    td.exif_name
      color: #3466a4
      width: 100px
      text-align: left
    td.exif_value
      text-align: left

#nonFooter
  position: relative
  min-height: 100%


* html #nonFooter
  height: 100%


#headerBG
  width: 100%
  height: 62px
  border-bottom: 1px solid silver


#headercontainer
  width: 1000px
  height: auto
  margin: 0 auto


#container
  width: 1000px
  height: auto
  margin: 0 auto
  padding-bottom: 10px


#menuheader
  width: 100%
  height: 63px
  text-align: right


#logo
  margin-top: 30px
  float: left
  color: #3466a4
  font-size: 24px


#menucontainer
  float: right
  height: 50px
  width: auto


ul#nav
  width: auto
  height: 50px
  list-style: none
  margin-top: 35px

  li
    float: left
    background-position: 0px 0px
    margin-left: 15px

    a
      display: block
      font-size: 18px
      color: #3466a4
      text-decoration: none

      &:hover
        text-decoration: underline


#webcontent
  height: auto
  clear: both

#sidemenu
  width: 300px
  height: auto
  float: right


.clearfix
  display: inline-block

  &:after
    content: "."
    display: block
    height: 0
    font-size: 0
    clear: both
    visibility: hidden


* html .clearfix
  height: 1px


.clearfix
  display: block


.menubox
  margin-top: 25px
  width: 100%
  border-left: 1px solid silver

ul
  &.sidemenulist
    width: auto
    list-style: none
    margin: 0
    padding: 0
    float: left
    clear: both

    li
      width: auto
      height: auto
      text-align: left
      font-size: 12px
      padding-left: 8px

      a
        height: auto
        color: #3466a4
        text-decoration: none

        &:hover
          text-decoration: underline

ul.thumbimagelist
  margin: 0
  padding: 0
  float: left
  clear: both
  width: auto
  height: auto
  list-style: none
  display: block
  border: 0

  li
    float: left
    width: 240px
    height: 240px
    display: block
    margin-left: 10px
    margin-bottom: 10px

    a
      display: table-cell
      width: 240px
      height: 240px
      text-align: center
      vertical-align: middle

      img
        vertical-align: middle

ul.albumlist
  margin: 0
  padding: 0
  float: left
  clear: both
  width: auto
  height: auto
  list-style: none
  display: block
  border: 0

  li
    float: left
    width: 490px
    height: 120px
    display: block
    margin-left: 10px
    margin-bottom: 10px

    div.albumPreview
      float: left
      width: 100px
      height: 90px

      a
        width: 90px
        height: 90px
        display: table-cell
        text-align: center
        vertical-align: middle

        img
          vertical-align: middle

    div.albumInfo
      float: left

      h1
        color: #3466a4
        clear: none
        border: 0
        margin: 0

      h4
        clear: none
        color: black
        border: 0
        padding: 0
        margin: 0
        font-style: italic
        font-size: 9px
        font-weight: normal

    p
      color: #333
#adminAlbumInfo
  margin-bottom: 30px

  img
    display: block
    clear: both
    margin: 0

  p
    clear: both
    color: #333

  div.buttonBar
    display: none
    clear: both

    input
      border: 1px solid #3466a4
      margin-left: 20px

.adminEntry
  height: 100px
  width: 100%
  clear: both

  a
    display: table-cell
    width: 100px
    height: 100px
    text-align: center
    vertical-align: middle
    float: left

    img
      vertical-align: middle

  div.descriptionBar
    float: left
    width: 300px
	
    p
      color: #333
      float: left
      margin-left: 20px
      margin-top: 0px

    div.buttonBar
      display: none
      float: left

      input
        border: 1px solid #3466a4
        margin-left: 20px
        float: left

  div.controlBar
    float: left
    width: 200px

    p
      clear: both
      float: left
      margin: 0px 0px 10px 0px
      width: 100%

      input
        border: 1px solid #3466a4
        margin-left: 20px
        float: left

.admindeletebar 
  clear: both

  input
    border: 1px solid #3466a4
    margin: 10px 20px 30px 0px
    float: left

#adminImageList
  div.loading
    display: table-cell
    width: 645px
    height: 645px
    text-align: center
    vertical-align: middle
    float: left

    img
      vertical-align: middle

p

  &#picturesrc
    margin: 0
    border: 0
    padding: 0
    text-align: center

#content
  width: 645px
  height: auto
  float: left
  margin: 25px 15px

#contentexif
  width: 645px
  height: auto
  float: left
  margin: 25px 15px

#contentlarge
  width: 1000px
  height: auto
  float: left
  margin: 25px 15px

#contentcontrols
  height: 16px
  width: auto
  display: inline-block
  margin-bottom: 5px
  float: left
  font-size: 12px
  color: #3466a4
  padding-bottom: 8px
  border-bottom: 1px solid silver

  a
    text-decoration: none
    color: #3466a4

    &:hover
      text-decoration: underline

#sizecontrols
  height: 16px
  width: auto
  display: inline-block
  margin-bottom: 5px
  float: right
  font-size: 12px
  color: #3466a4
  padding-bottom: 8px
  border-bottom: 1px solid silver

  a
    text-decoration: none
    color: #3466a4

    &:hover
      text-decoration: underline

#footer
  border-top: 1px solid silver
  width: 100%
  height: 24px
  clear: both
  position: relative
  margin-top: -25px


#footercontent
  width: 1000px
  height: auto
  margin: auto
  color: gray
  padding-top: 4px
  text-align: center


.currentPage
  color: silver
  font-weight: bold

#jquery-overlay
  position: absolute
  top: 0
  left: 0
  z-index: 90
  width: 100%
  height: 500px


#jquery-lightbox
  position: absolute
  top: 0
  left: 0
  width: 100%
  z-index: 100
  text-align: center
  line-height: 0

  a img
    border: none


#lightbox-container-image-box
  position: relative
  background-color: #fff
  width: 250px
  height: 250px
  margin: 0 auto


#lightbox-container-image
  padding: 10px


#lightbox-loading
  position: absolute
  top: 40%
  left: 0%
  height: 25%
  width: 100%
  text-align: center
  line-height: 0


#lightbox-nav
  position: absolute
  top: 0
  left: 0
  height: 100%
  width: 100%
  z-index: 10


#lightbox-container-image-box > #lightbox-nav
  left: 0


#lightbox-nav a
  outline: none


#lightbox-nav-btnPrev, #lightbox-nav-btnNext
  width: 49%
  height: 100%
  display: block


#lightbox-nav-btnPrev
  left: 0
  float: left


#lightbox-nav-btnNext
  right: 0
  float: right


#lightbox-container-image-data-box
  font: 10px Verdana, Helvetica, sans-serif
  background-color: #fff
  margin: 0 auto
  line-height: 1.4em
  overflow: auto
  width: 100%
  padding: 0 10px 0


#lightbox-container-image-data
  padding: 0 10px
  color: #666

  #lightbox-image-details
    width: 70%
    float: left
    text-align: left


#lightbox-image-details-caption
  font-weight: bold


#lightbox-image-details-currentNumber
  display: block
  clear: left
  padding-bottom: 1.0em


#lightbox-secNav-btnClose
  width: 66px
  float: right
  padding-bottom: 0.7em

.statusSuccess
  font-weight: bold
  font-size: 14px
  color: green

.statusFail
  font-weight: bold
  font-size: 14px
  color: red
  
.blue
  color: #3466a4

@@ layoutlarge
!!! Strict
%html
	%head
		%title #{CONFIG['title']}
		%meta(http-equiv="Content-Type" content="text/html; charset=utf-8")
		%link{:type => "text/css", :href  => "/resources/css", :rel => "stylesheet"}
	%body
		#nonFooter
			#headerBG
				#headercontainer
					#menuheader
						#logo #{CONFIG['title']}
						#menucontainer
							%ul#nav
								- if CONFIG['navigation'] then
									- CONFIG['navigation'].each do |key, value|
										%li
											%a{ :href => value } #{key}
				#container
					#webcontent
						#contentlarge 
							= yield
		#footer
			#footercontent #{CONFIG['footer']}
@@ layoutexif
!!! Strict
%html
	%head
		%title #{CONFIG['title']}
		%meta(http-equiv="Content-Type" content="text/html; charset=utf-8")
		%link{:type => "text/css", :href  => "/resources/css", :rel => "stylesheet"}
		%script{:type => "text/javascript", :src  => "http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"}
		- @resources.each do |resource|
			%script{:type => "text/javascript", :src  => '/resources/js/' + resource }

	%body
		#nonFooter
			#headerBG
				#headercontainer
					#menuheader
						#logo #{CONFIG['title']}
						#menucontainer
							%ul#nav
								- if CONFIG['navigation'] then
									- CONFIG['navigation'].each do |key, value|
										%li
											%a{ :href => value } #{key}
				#container
					#webcontent
						= yield

		#footer
			#footercontent #{CONFIG['footer']}

@@ index
%ul.albumlist
	- @albumList.each do |item|
		%li
			.albumPreview
				%a{ :href => '/album/' + item }
					%img{ :src => @albumPreview[item], :alt => @albumPreview[item] }
			.albumInfo
				%h1
					%a{ :href => '/album/' + item } #{Haml::Helpers.html_escape(item)}
				%h4 #{@albumNumbers[item]} pictures
				%h4 last modified #{@albumModified[item]}
				%p #{Haml::Helpers.html_escape(@albumDescription[item])}

@@ album
#contentcontrols
	#{@paginate}
#sizecontrols
	%a{ :href => '/'} Gallery Home
%h1 #{Haml::Helpers.html_escape(@albumName)}
%ul#rawimagelist.thumbimagelist
	- @pictureList.each do |item|
		%li
			%a{ :href => '/view/' + @albumName + '/' + item }
				%img{ :src => '/resize/240/' + @albumName + '/' + item , :alt => item }
	
@@ imageexif
#contentlarge
	#contentcontrols
		- if @prevImage then
			%a{ :href => '/view/' + @albumName + '/' + @prevImage } < Prev
			&nbsp;|&nbsp;
		%a{ :href => '/album/' + @albumName + '/' + @backPage} Back to Album
		&nbsp;|&nbsp;
		%a{ :href => '/'} Gallery Home
		- if @nextImage then
			&nbsp;|&nbsp;
			%a{ :href => '/view/' + @albumName + '/' + @nextImage } Next >
	
	%h1 #{Haml::Helpers.html_escape(@albumName)} (#{@currentImageNumber} of #{@totalImages})
#contentexif
	%p#picturesrc
		%img{ :src => '/resize/645/' + @albumName + '/' + @currentPicture, :alt => @currentPicture }
	%p #{Haml::Helpers.html_escape(@pictureDescription)}
#sidemenu 
	.clearfix.menubox
		%ul.sidemenulist
			%li
				%table
					%tr
						%td.exif_name Make:
						%td.exif_value #{@exif["Make"]}
					%tr
						%td.exif_name Model:
						%td.exif_value #{@exif["Model"]}
					%tr
						%td.exif_name Focal Length:
						%td.exif_value #{@exif["Focal"]}
					%tr
						%td.exif_name Exposure Time:
						%td.exif_value #{@exif["Exposure"]}
					%tr
						%td.exif_name F-Number:
						%td.exif_value #{@exif["Aperture"]}
					%tr
						%td.exif_name ISO Speed:
						%td.exif_value #{@exif["ISO"]}
	.clearfix.menubox
		%ul.sidemenulist
			- if @imageSize > 1024 then 
				%li
					%a{ :href => '/view/1024/' + @albumName + '/' + @currentPicture } View at 1024px
			- if @imageSize > 1280 then 
				%li
					%a{ :href => '/view/1280/' + @albumName + '/' + @currentPicture } View at 1280px
			- if @imageSize > 1600 then 
				%li
					%a{ :href => '/view/1600/' + @albumName + '/' + @currentPicture } View at 1600px
			%li
				%a{ :href => '/view/original/' + @albumName + '/' + @currentPicture } Original Size

@@ image
#contentcontrols
	- if @prevImage then
		%a{ :href => '/view/' + @imageView + '/' + @albumName + '/' + @prevImage } < Prev
		&nbsp;|&nbsp;
	%a{ :href => '/album/' + @albumName + '/' + @backPage} Back to Album
	&nbsp;|&nbsp;
	%a{ :href => '/'} Gallery Home
	- if @nextImage then
		&nbsp;|&nbsp;
		%a{ :href => '/view/' + @imageView + '/' + @albumName + '/' + @nextImage } Next >
		
#sizecontrols
	View:&nbsp;
	%a{ :href => '/view/' + @albumName + '/' + @currentPicture } Picture Information
	&nbsp;|&nbsp;
	- if @imageSize > 1024 then 
		- if @imageView == '1024' then
			%span.currentPage 1024px
		- else
			%a{ :href => '/view/1024/' + @albumName + '/' + @currentPicture } 1024px
		&nbsp;|&nbsp;
	- if @imageSize > 1280 then 
		- if @imageView == '1280' then
			%span.currentPage 1280px
		- else
			%a{ :href => '/view/1280/' + @albumName + '/' + @currentPicture } 1280px
		&nbsp;|&nbsp;
	- if @imageSize > 1600 then 
		- if @imageView == '1600' then
			%span.currentPage 1600px
		- else
			%a{ :href => '/view/1600/' + @albumName + '/' + @currentPicture } 1600px
		&nbsp;|&nbsp;
	- if @imageView == 'original' then
		%span.currentPage Original Size
	- else
		%a{ :href => '/view/original/' + @albumName + '/' + @currentPicture } Original Size
	
%h1 #{Haml::Helpers.html_escape(@albumName)} (#{@currentImageNumber} of #{@totalImages})
%p
	%img{ :src => @pictureURL, :alt => @currentPicture }


@@ adminlayout
!!! Strict
%html
	%head
		%title #{CONFIG['title']}
		%meta(http-equiv="Content-Type" content="text/html; charset=utf-8")
		%link{:type => "text/css", :href  => "/resources/css", :rel => "stylesheet"}
		%script{:type => "text/javascript", :src  => "http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"}
		- @resources.each do |resource|
			%script{:type => "text/javascript", :src  => '/resources/js/' + resource }
	%body
		#nonFooter
			#headerBG
				#headercontainer
					#menuheader
						#logo #{CONFIG['title']}
						#menucontainer
							%ul#nav
								- if CONFIG['navigation'] then
									- CONFIG['navigation'].each do |key, value|
										%li
											%a{ :href => value } #{key}
				#container
					#webcontent
						#content 
							= yield
						#sidemenu 
							.clearfix.menubox
								%ul.sidemenulist
									%li
										%a{ :href => '/' } Gallery Home
									%li
										%a{ :href => '/admin' } Administration Home
							.clearfix.menubox
								%ul.sidemenulist
									%li
										%a{ :href => '/admin/create' } Create Album
									%li
										%a{ :href => '/admin/upload' } Upload Pictures
							- if @adminList then
								.clearfix.menubox
									%ul#adminalbumlist.sidemenulist
										- @adminList.each do |item|
											%li
												%a{ :href => '/admin/album/' + item + '/1' } #{Haml::Helpers.html_escape(item)}
		#footer
			#footercontent #{CONFIG['footer']}

@@ admin
%h1 Welcome to the Administration Panel

@@ adminalbum
#contentcontrols #{@paginate}
#adminAlbumInfo
	%img{ :alt => @albumPreview, :src => @albumPreview }
	%h1 #{Haml::Helpers.html_escape(@albumName)}
	- if @albumDescription != nil then
		%p #{Haml::Helpers.html_escape(@albumDescription)}
	- else
		%p <i>Click to add description</i>
	%p{ :style => 'display: none;' }
		%textarea
	.buttonBar
		%input{ :value => 'Save', :type => 'submit'}
		%input{ :value => 'Cancel', :type => 'reset'}
#topdeletebar.admindeletebar
	%input{ :value => 'Delete this album', :type => 'button' }
	%input{ :value => 'Delete selected pictures', :type => 'button' }
#adminImageList
	- @pictureList.each do |image|
		.adminEntry
			%a{ :href => '/resize/645/' + @albumName + '/' + image }
				%img{ :alt => image, :src => '/resize/90/' + @albumName + '/' + image }
			.controlBar
				%p
					%input{ :value => 'Set as album preview', :type => 'button' }
				%p
					%input{ :type => 'checkbox' }
					\Delete this picture
			.descriptionBar
				- if @picturesDescription[image] != nil then
					%p #{Haml::Helpers.html_escape(@picturesDescription[image])}
				- else
					%p <i>Click to add description</i>
				%p{ :style => 'display: none;' }
					%textarea
				.buttonBar
					%input{ :value => 'Save', :type => 'submit' }
					%input{ :value => 'Cancel', :type => 'reset' }
#bottomdeletebar.admindeletebar
	%input{ :value => 'Delete this album', :type => 'button' }
	%input{ :value => 'Delete selected pictures', :type => 'button' }

@@ adminupload
%h1 Upload Pictures
%p
%form#uploadform{ :action => '/admin/upload', :method => 'post', :enctype => 'multipart/form-data' }
	%p
		%label{ :for => 'album' } Album:
		%select{ :name => 'album' }
			- @adminList.each do |album|
				%option{ :value => album } #{Haml::Helpers.html_escape(album)}
	%p
		%input#multiupload{ :type => 'file', :name => 'MyImages[]'}
	%p
		%input{ :type => 'submit', :value => 'Upload' }
%p
	%a#resetQueue{ :href => '#'} Clear Queue
%p#status

@@ admincreate
%h1 Create a new album
%p
%form{ :action => '/admin/create', :method => 'post' }
	%input{ :name => 'name', :type => 'text'}
	%input{ :value => 'Create', :type => 'submit'}

@@ adminstatus
- if @status['success']
	%p.statusSuccess #{@status['message']}
- else
	%p.statusFail #{@status['message']}

@@ error
#contentcontrols
	%a{ :href => '/'} Home
%h1 404 Not Found

@@ errormessage
#contentcontrols
	%a{ :href => '/'} Home
%h1 Error
%p.statusFail @errormessage
