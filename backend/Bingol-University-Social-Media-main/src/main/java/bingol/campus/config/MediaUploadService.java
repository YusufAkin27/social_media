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

        if (contentType.startsWith("image/")) {
            return uploadAndOptimizeImage(file);
        } else if (contentType.startsWith("video/")) {
            return uploadAndOptimizeVideo(file);
        } else {
            throw new OnlyPhotosAndVideosException();
        }
    }

    @Async
    private CompletableFuture<String> uploadAndOptimizeImage(MultipartFile photo) throws IOException, PhotoSizeLargerException {
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
    private CompletableFuture<String> uploadAndOptimizeVideo(MultipartFile video) throws IOException, VideoSizeLargerException {
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
