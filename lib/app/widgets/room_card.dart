import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import '../models/room_model.dart';
import 'status_badge.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoomCard({
    Key? key,
    required this.room,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _buildPhoto(),
                ),
                
                // Status badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: StatusBadge(status: room.status),
                ),
                
                // Actions
                if (onEdit != null || onDelete != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        if (onEdit != null)
                          _buildActionButton(
                            Icons.edit,
                            const Color(0xFFA9C9FF),
                            onEdit!,
                          ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 4),
                          _buildActionButton(
                            Icons.delete,
                            Colors.red,
                            onDelete!,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kamar ${room.roomNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${room.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (room.currentTenantName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            room.currentTenantName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (room.photos.isEmpty) {
      return Container(
        height: 120,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image, size: 48, color: Colors.grey),
        ),
      );
    }

    // TODO: Uncomment when cached_network_image is added
    // return CachedNetworkImage(
    //   imageUrl: room.photos.first,
    //   height: 120,
    //   width: double.infinity,
    //   fit: BoxFit.cover,
    //   placeholder: (context, url) => Container(
    //     height: 120,
    //     color: Colors.grey.shade200,
    //     child: const Center(child: CircularProgressIndicator()),
    //   ),
    //   errorWidget: (context, url, error) => Container(
    //     height: 120,
    //     color: Colors.grey.shade300,
    //     child: const Icon(Icons.error),
    //   ),
    // );

    // Temporary: Use Image.network
    return Image.network(
      room.photos.first,
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 120,
        color: Colors.grey.shade300,
        child: const Icon(Icons.error),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
