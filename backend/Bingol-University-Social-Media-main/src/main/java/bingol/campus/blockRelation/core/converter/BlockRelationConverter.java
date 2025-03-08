package bingol.campus.blockRelation.core.converter;

import bingol.campus.blockRelation.core.response.BlockUserDTO;
import bingol.campus.blockRelation.entity.BlockRelation;

public interface BlockRelationConverter {


    BlockUserDTO toDTO(BlockRelation blockRelation);
}
