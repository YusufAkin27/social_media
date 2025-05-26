package bingol.campus.config;

import bingol.campus.student.exceptions.FileFormatCouldNotException;
import bingol.campus.student.exceptions.OnlyPhotosAndVideosException;
import bingol.campus.student.exceptions.PhotoSizeLargerException;
import bingol.campus.student.exceptions.VideoSizeLargerException;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.cloudinary.Transformation;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
public class MediaUploadService {

    private final Cloudinary cloudinary;

    private static final long MAX_IMAGE_SIZE = 5 * 1024 * 1024;
    private static final long MAX_VIDEO_SIZE = 50 * 1024 * 1024;

    @Async
    public CompletableFuture<String> uploadAndOptimizeMedia(MultipartFile file) throws IOException, VideoSizeLargerException, OnlyPhotosAndVideosException, PhotoSizeLargerException, FileFormatCouldNotException {
        String contentType = file.getContentType();

        if (contentType == null) {
            throw new FileFormatCouldNotException();
        }

        contentType = contentType.toLowerCase();

        if (contentType.startsWith("image/")) {
            return uploadAndOptimizeImage(file);
        } else if (contentType.startsWith("video/")) {
            return uploadAndOptimizeVideo(file);
        } else {
            String filename = file.getOriginalFilename();
            if (filename != null) {
                filename = filename.toLowerCase();
                if (filename.endsWith(".jpg") || filename.endsWith(".jpeg") || filename.endsWith(".png") ||
                        filename.endsWith(".gif") || filename.endsWith(".heic") || filename.endsWith(".heif") ||
                        filename.endsWith(".webp") || filename.endsWith(".bmp") ||
                        filename.endsWith(".mp4") || filename.endsWith(".mov") || filename.endsWith(".avi") ||
                        filename.endsWith(".mkv") || filename.endsWith(".webm") || filename.endsWith(".3gp")) {

                    // Video uzantıları
                    if (filename.endsWith(".mp4") || filename.endsWith(".mov") || filename.endsWith(".avi") ||
                            filename.endsWith(".mkv") || filename.endsWith(".webm") || filename.endsWith(".3gp")) {
                        return uploadAndOptimizeVideo(file);
                    } else {
                        // Fotoğraf uzantıları
                        return uploadAndOptimizeImage(file);
                    }
                }
            }
            throw new OnlyPhotosAndVideosException();
        }
    }



    @Async
    public CompletableFuture<String> uploadAndOptimizeImage(MultipartFile photo) throws IOException, PhotoSizeLargerException {
        if (photo.getSize() > MAX_IMAGE_SIZE) {
            throw new PhotoSizeLargerException();
        }

        Map<String, String> uploadResult = cloudinary.uploader().upload(photo.getBytes(), ObjectUtils.asMap(
                "folder", "profile_photos",
                "quality", "auto:best",
                "format", "webp",
                "transformation", new Transformation()
                        .width(1280)
                        .height(1280)
                        .crop("limit")
        ));

        return CompletableFuture.completedFuture(uploadResult.get("url"));
    }

    @Async
    public CompletableFuture<String> uploadAndOptimizeVideo(MultipartFile video) throws IOException, VideoSizeLargerException {
        if (video.getSize() > MAX_VIDEO_SIZE) {
            throw new VideoSizeLargerException();
        }

        Map<String, String> uploadResult = cloudinary.uploader().upload(video.getBytes(), ObjectUtils.asMap(
                "folder", "profile_videos",
                "resource_type", "video",
                "format", "mp4",
                "quality", "auto",
                "transformation", new Transformation()
                        .width(1920)
                        .height(1080)
                        .crop("limit")
        ));

        return CompletableFuture.completedFuture(uploadResult.get("url"));
    }
}
