package bingol.campus.blockRelation.core.converter;

import bingol.campus.blockRelation.core.response.BlockUserDTO;
import bingol.campus.blockRelation.entity.BlockRelation;
import org.springframework.stereotype.Component;

@Component
public class BlockRelationConverterImpl implements BlockRelationConverter {
    @Override
    public BlockUserDTO toDTO(BlockRelation blockRelation) {
        return BlockUserDTO.builder()
                .profilePhoto(blockRelation.getBlocked().getProfilePhoto())
                .blockDate(blockRelation.getBlockDate())
                .firstName(blockRelation.getBlocked().getFirstName())
                .lastName(blockRelation.getBlocked().getLastName())
                .username(blockRelation.getBlocked().getUsername())
        .build();

    }
}
